# NOTE check out "https://www.kaggle.com/wsj/college-salaries"

from bs4 import BeautifulSoup
import requests
import re
import json
from tqdm import tqdm
from csv import DictReader

SITE = "https://www.ratemyprofessors.com"
HARVARD = f"{SITE}/search.jsp?queryoption=HEADER&queryBy=teacherName&schoolName=Harvard+University&schoolID=399&query=*"


def parse_page(soup):
    professors = soup.find_all(class_="listing PROFESSOR")
    professor_links = [prof.find("a").get("href") for prof in professors]
    # print(professor_links)
    professor_info = []
    strip_department = re.compile(" department")
    for link in tqdm(professor_links, desc="Parsing Page"):
        prof_response = requests.get(f"{SITE}{link}")
        prof_soup = BeautifulSoup(prof_response.content, "html.parser")

        name = prof_soup.find(class_="NameTitle__Name-dowf0z-0 cjgLEI")

        rating = prof_soup.find(
            class_="RatingValue__Numerator-qw8sqy-2 gxuTRq"
        )

        difficulty = prof_soup.find_all(
            class_="FeedbackItem__FeedbackNumber-uof32n-1 bGrrmf"
        )

        department = strip_department.sub("", prof_soup.find("b").text)

        if name == None or rating == None or difficulty == []:
            continue

        if len(difficulty) == 1:
            difficulty_text = difficulty[0].text
        else:
            difficulty_text = difficulty[1].text
        # print(name)
        professor_info.append({
            "name": name.text,
            "rating": float(rating.text),
            "difficulty": float(difficulty_text),
            "department": department
        })
    return professor_info


def parse_college(url):
    response = requests.get(url)
    soup = BeautifulSoup(response.content, "html.parser")
    pages = soup.find_all(class_="step")
    page_links = [page.get("href") for page in pages]
    professors = parse_page(soup)
    for page_link in tqdm(page_links, desc="Parsing College"):
        if page_link == None:
            continue
        page_response = requests.get(f"{SITE}{page_link}")
        page_soup = BeautifulSoup(page_response.content, "html.parser")
        professors += parse_page(page_soup)
    return professors


if __name__ == "__main__":
    with open("./college-salaries/salaries-by-college-type.csv") as csvfile:
        reader = DictReader(csvfile)
        colleges = [row["School Name"] for row in reader]
    profs_by_college = {}
    profs_by_college["Harvard"] = parse_college(HARVARD)
    with open("professor_ratings_by_college.json", "w+") as f:
        f.write(json.dumps(profs_by_college))

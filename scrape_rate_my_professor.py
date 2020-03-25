# NOTE check out "https://www.kaggle.com/wsj/college-salaries"

from bs4 import BeautifulSoup
import requests
import re
import json
from tqdm import tqdm
from csv import DictReader

SITE = "https://www.ratemyprofessors.com"
HARVARD = f"{SITE}/search.jsp?queryoption=HEADER&queryBy=teacherName&schoolName=Harvard+University&schoolID=399&query=*"


def college_search(college):
    college_no_spaces = re.sub(" ", "+", college)
    college_url = f"{SITE}/search.jsp?queryoption=HEADER&queryBy=teacherName&schoolName={college_no_spaces}&query=*"
    college_response = requests.get(college_url)
    college_soup = BeautifulSoup(college_response.content, "html.parser")
    if college_soup.find("div", class_="result-count").text == "Your search didn't return any results.":
        print(college, college_url, "was not found")
        return []
    return parse_college(college_url)


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

        department_tag = prof_soup.find("b")
        department = "NA"
        if department_tag != None:
            department = strip_department.sub("", department_tag.text)

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
    strip_acronym = re.compile(r" \([\w\W]*\)")
    with open("./college-salaries/salaries-by-college-type-reduced-3.csv") as csvfile:
        reader = DictReader(csvfile)
        colleges = [
            strip_acronym.sub("", row["School Name"])
            for row in reader
        ]

    profs_by_college = {}
    # profs_by_college["Harvard"] = parse_college(HARVARD)
    for college in colleges:
        profs_by_college[college] = college_search(college)
    with open("professor_ratings_by_college.json", "w+") as f:
        f.write(json.dumps(profs_by_college))
    print("done")

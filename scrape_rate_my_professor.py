# NOTE check out "https://www.kaggle.com/wsj/college-salaries"

from bs4 import BeautifulSoup
import requests
import re


SITE = "https://www.ratemyprofessors.com"
HARVARD = f"{SITE}/search.jsp?queryoption=HEADER&queryBy=teacherName&schoolName=Harvard+University&schoolID=399&query=*"


def parse_page(soup):
    professors = soup.find_all(class_="listing PROFESSOR")
    professor_links = [prof.find("a").get("href") for prof in professors]
    # print(professor_links)
    professor_info = {}
    for link in professor_links:
        prof_response = requests.get(f"{SITE}{link}")
        prof_soup = BeautifulSoup(prof_response.content, "html.parser")
        name = prof_soup.find(class_="NameTitle__Name-dowf0z-0 cjgLEI")
        rating = prof_soup.find(
            class_="RatingValue__Numerator-qw8sqy-2 gxuTRq"
        )
        if rating == None:
            continue
        difficulty = prof_soup.find(
            class_="FeedbackItem__FeedbackNumber-uof32n-1 bGrrmf"
        )
        if difficulty == None:
            continue
        # print(name)
        professor_info[name.text] = {
            "rating": rating.text,
            "difficulty": difficulty.text
        }
    return professor_info


if __name__ == "__main__":
    response = requests.get(HARVARD)
    soup = BeautifulSoup(response.content, "html.parser")
    pages = soup.find_all(class_="step")
    page_links = [page.get("href") for page in pages]
    professors = [parse_page(soup)]
    print(professors)
    for page_link in page_links:
        page_response = requests.get(f"{SITE}{page_link}")
        page_soup = BeautifulSoup(page_response.content, "html.parser")
        prof = parse_page(page_soup)
        print(prof)

# TODO make sure links are not none

import os
import requests

GITHUB_API_URL = "https://api.github.com"
NOTION_API_URL = "https://api.notion.com/v1"

def get_github_issues():
    headers = {
        "Authorization": f"token {os.getenv('HUB_TOKEN')}"
    }
    response = requests.get(f"{GITHUB_API_URL}/repos/Coding-Community-of-Central-Texas/NeverFear/issues", headers=headers)
    return response.json()

def create_notion_page(issue):
    headers = {
        "Authorization": f"Bearer {os.getenv('NOTION_TOKEN')}",
        "Content-Type": "application/json",
        "Notion-Version": "2021-05-13"
    }
    data = {
        "parent": {"database_id": os.getenv('NOTION_DATABASE_ID')},
        "properties": {
            "Name": {"title": [{"text": {"content": issue['title']}}]},
            "Description": {"rich_text": [{"text": {"content": issue['body']}}]},
            "URL": {"url": issue['html_url']}
        }
    }
    response = requests.post(f"{NOTION_API_URL}/pages", headers=headers, json=data)
    return response.json()

if __name__ == "__main__":
    issues = get_github_issues()
    for issue in issues:
        create_notion_page(issue)

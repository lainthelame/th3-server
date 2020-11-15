import requests

while True:
    url = 'http://127.0.0.1:8080/version'

    response = requests.get(url)
    data = response.json()

    print(data)
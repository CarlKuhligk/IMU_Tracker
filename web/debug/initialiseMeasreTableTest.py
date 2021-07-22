import requests

url = 'http://127.0.0.1/imutracker/api/initialiseMeasureTable.php'
myData = {"api_key":"kzNABRcbVBQghFDC"}

x = requests.post(url, data = myData)

print(myData)
print(x.text)
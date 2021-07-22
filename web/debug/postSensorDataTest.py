import requests

url = 'http://127.0.0.1/imutracker/api/postSensorData.php'
myData = {"api_key":"28e7ebccfe374ccf75c3ec83fbc2805ec6131ab4d1aba6d859726e9b99cde835","accX":5.97,"accY":0.06,"accZ":6.81,"gyrX":-0.04,"gyrY":0.00,"gyrZ":0.01,"temp":33.59}

x = requests.post(url, data = myData)

print(myData)
print(x.text)
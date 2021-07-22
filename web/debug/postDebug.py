import requests

url = 'http://172.24.192.1/imutracker/api/postSensorData.php'
myData = {"api_key":"kzNABRcbVBQghFDC","accX":5.97,"accY":0.06,"accZ":6.81,"gyrX":-0.04,"gyrY":0.00,"gyrZ":0.01,"temp":33.59}

x = requests.post(url, data = myData)

print(myData)
print(x.text)
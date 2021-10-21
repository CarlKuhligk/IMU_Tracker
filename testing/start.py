import datetime
import pathlib
import websocket

# _____Tests_________________________
import test_1_connect_websocket
import test_2_unknown_datatype
import test_3_missing_data
import test_4_sender_missing_apikey
import test_5_sender_invalid_apikey
import test_6_sender_regestration
import test_7_global_channel_update
import test_8_sender_double_regestration
import test_9_subscriber_missing_channel_id
import test_10_subscriber_invalid_channel_id
import test_11_subscriber_missing_data
import test_12_subscriber_subscribe
import test_14_subscriber_sender_regestration
import test_15_subscriber_double_subscribe


# ___________________________________
def log(message):
    logFile.writelines(message + "\n")


wsMaster = websocket.WebSocket()
wsClient1 = websocket.WebSocket()
wsClient2 = websocket.WebSocket()

# create new logfile
fileDirectory = str(pathlib.Path().resolve()) + "/testing/results/"
datetime_object = datetime.datetime.now()
logFile = open(
    fileDirectory + datetime_object.strftime(("%d_%m_%Y %H_%M_%S") + ".txt"),
    "w",
)

# CALLING TESTS
log("Start testing\n")

if test_1_connect_websocket.test(wsMaster, wsClient1, wsClient2):
    log("Test 1: success -> websocket is connected")
else:
    log("Test 1: faild -> websocket is not connected")
    exit

result, message = test_2_unknown_datatype.test(wsMaster)
if result:
    log("Test 2: success -> " + message)
else:
    log("Test 2: faild -> " + message)
    exit

result, message = test_3_missing_data.test(wsMaster)
if result:
    log("Test 3: success -> " + message)
else:
    log("Test 3: faild -> " + message)
    exit

result, message = test_4_sender_missing_apikey.test(wsMaster)
if result:
    log("Test 4: success -> " + message)
else:
    log("Test 4: faild -> " + message)
    exit

result, message = test_5_sender_invalid_apikey.test(wsMaster)
if result:
    log("Test 5: success -> " + message)
else:
    log("Test 5: faild -> " + message)
    exit

result, message = test_6_sender_regestration.test(wsMaster)
if result:
    log("Test 6: success -> " + message)
else:
    log("Test 6: faild -> " + message)
    exit

result, message = test_7_global_channel_update.test(wsMaster, wsClient1, wsClient2)
if result:
    log("Test 7: success -> " + message)
else:
    log("Test 7: faild -> " + message)
    exit

result, message = test_8_sender_double_regestration.test(wsMaster)
if result:
    log("Test 8: success -> " + message)
else:
    log("Test 8: faild -> " + message)
    exit

result, message = test_9_subscriber_missing_channel_id.test(wsClient1)
if result:
    log("Test 9: success -> " + message)
else:
    log("Test 9: faild -> " + message)
    exit

result, message = test_10_subscriber_invalid_channel_id.test(wsClient1)
if result:
    log("Test 10: success -> " + message)
else:
    log("Test 10: faild -> " + message)
    exit

result, message = test_11_subscriber_missing_data.test(wsClient1)
if result:
    log("Test 11: success -> " + message)
else:
    log("Test 11: faild -> " + message)
    exit

result, message = test_12_subscriber_subscribe.test(wsClient1)
if result:
    log("Test 12: success -> " + message)
else:
    log("Test 12: faild -> " + message)
    exit

result, message = test_7_global_channel_update.test(wsMaster, wsClient1, wsClient2)
if result:
    log("Test 13: success -> " + message)
else:
    log("Test 13: faild -> " + message)
    exit


# result, message = test_14_subscriber_sender_regestration.test(wsClient1)
# if result:
#    log("Test 14: success -> " + message)
# else:
#    log("Test 14: faild -> " + message)
#    exit

result, message = test_15_subscriber_double_subscribe.test(wsClient1)
if result:
    log("Test 15: success -> " + message)
else:
    log("Test 15: faild -> " + message)
    exit


wsMaster.close()
wsClient1.close()
wsClient2.close()


myData = {
    "api_key": "",
    "accX": 5.97,
    "accY": 0.06,
    "accZ": 6.81,
    "gyrX": -0.04,
    "gyrY": 0.00,
    "gyrZ": 0.01,
    "temp": 33.59,
}

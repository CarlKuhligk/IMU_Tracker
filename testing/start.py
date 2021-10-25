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
import test_16_not_authenticated_as_sender

# ___________________________________
def log(message):
    logFile.writelines(message + "\n")


def test(description, func, *args):
    test.testNum += 1
    result, response = func(*args)
    log(
        "| %.3i | %-30s | %5s |     %3s     |"
        % (test.testNum, description, result, response)
    )
    if not result:
        logFile.close
        exit


test.testNum = 0

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
log("___________________________________________________________")
log("|Test | Description                    | Passed| Response ID |")

test(
    "connect websocket",
    test_1_connect_websocket.test,
    wsMaster,
    wsClient1,
    wsClient2,
)

test("unknown datatype", test_2_unknown_datatype.test, wsMaster)

test("missing data", test_3_missing_data.test, wsMaster)

test("empty apikey", test_4_sender_missing_apikey.test, wsMaster)

test("invalid apikey", test_5_sender_invalid_apikey.test, wsMaster)

test("correct apikey", test_6_sender_regestration.test, wsMaster)
test(
    "global channel update",
    test_7_global_channel_update.test,
    wsMaster,
    wsClient1,
    wsClient2,
)
test("double sender regestration", test_8_sender_double_regestration.test, wsMaster)

test("subscribe, no channel id", test_9_subscriber_missing_channel_id.test, wsClient1)

test(
    "subscribe, invalid channel id",
    test_10_subscriber_invalid_channel_id.test,
    wsClient1,
)
test("subscribe, no data", test_11_subscriber_missing_data.test, wsClient1)

test("subscribe", test_12_subscriber_subscribe.test, wsClient1)

test(
    "global channel update",
    test_7_global_channel_update.test,
    wsMaster,
    wsClient1,
    wsClient2,
)

# test("sender reg as subscriber", test_14_subscriber_sender_regestration.test, wsClient1)

test("double subscribe", test_15_subscriber_double_subscribe.test, wsClient1)

test("not authenticated as sender", test_16_not_authenticated_as_sender.test, wsClient2)

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

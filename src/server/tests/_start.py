import datetime
import pathlib
import websocket
import os
import platform

# _____Tests_________________________
import connect_websocket
import unknown_datatype
import missing_data
import sender_missing_apikey
import sender_invalid_apikey
import sender_regestration
import global_channel_update
import sender_double_regestration
import subscriber_missing_channel_id
import subscriber_invalid_channel_id
import subscriber_missing_data
import subscriber_subscribe
import subscriber_sender_regestration
import subscriber_double_subscribe
import not_authenticated_as_sender

# ___________________________________
# create new logfile
fileDirectory = str(pathlib.Path().resolve()) + "/testing/results/"
start_datetime_object = datetime.datetime.now()


def log(message):
    logFile = open(
        fileDirectory + start_datetime_object.strftime(("%d_%m_%Y %H_%M_%S") + ".txt"),
        "a",
    )
    logFile.writelines(message + "\n")
    logFile.close


def test(description, func, *args):
    test.count += 1
    result, response = func(*args)
    log(
        "| %.3i | %-30s | %5s |     %3s     |"
        % (test.count, description, result, response)
    )
    test.passed += 1
    if not result:
        return ()


test.count = 0
test.passed = 0

wsMaster = websocket.WebSocket()
wsClient1 = websocket.WebSocket()
wsClient2 = websocket.WebSocket()


# CALLING TESTS
log(
    "WEBSOCKETTEST "
    + start_datetime_object.strftime("Date: %d.%m.%Y Time: %H:%M:%S")
    + "\n"
)
log("--------------------------------------------------------------")
log("|Test | Description                    | Passed| Response ID |")
log("--------------------------------------------------------------")

test(
    "connect websocket",
    connect_websocket.test,
    wsMaster,
    wsClient1,
    wsClient2,
)

test("unknown datatype", unknown_datatype.test, wsMaster)

test("missing data", missing_data.test, wsMaster)

test("empty apikey", sender_missing_apikey.test, wsMaster)

test("invalid apikey", sender_invalid_apikey.test, wsMaster)

test("subscribe, no channel id", subscriber_missing_channel_id.test, wsClient1)

test(
    "subscribe, invalid channel id",
    subscriber_invalid_channel_id.test,
    wsClient1,
)
test("subscribe, no data", subscriber_missing_data.test, wsClient1)

test("subscribe", subscriber_subscribe.test, wsClient1)

test("correct apikey", sender_regestration.test, wsMaster)

test("global channel update", global_channel_update.test, wsClient1)

test("double sender regestration", sender_double_regestration.test, wsMaster)

test("global channel update", global_channel_update.test, wsClient1)

# test("sender reg as subscriber", subscriber_sender_regestration.test, wsClient1)

test("double subscribe", subscriber_double_subscribe.test, wsClient1)

test("not authenticated as sender", not_authenticated_as_sender.test, wsClient2)

wsMaster.close()
wsClient1.close()
wsClient2.close()


log("---------------------------------------------------------------\n")


# track time
datetime_object = datetime.datetime.now()
log("TEST FINISHED " + datetime_object.strftime("Date: %d.%m.%Y Time: %H:%M:%S"))

duration = datetime_object - start_datetime_object
log("TEST DURATION: " + str(duration))

log("TEST RESULT: " + str(test.passed) + " / " + str(test.count) + " PASSED")
log(
    "EXECUTED BY: "
    + str(os.getlogin())
    + " ON "
    + platform.system()
    + " VERSION: "
    + platform.release()
)


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

import websocket
import json


def test(ws, c1, c2):
    message = json.loads(ws.recv())
    message1 = json.loads(c1.recv())
    message2 = json.loads(c2.recv())
    if message == message1 and message == message2:
        result = ""
        if message["type"] == "update":
            if message["channel"]["id"] == "16":
                result = (
                    "\nchannel: "
                    + message["channel"]["name"]
                    + "\n id: "
                    + message["channel"]["id"]
                    + "\n online: "
                    + str(message["channel"]["online"])
                    + "\n reciver: "
                    + str(message["channel"]["reciver"])
                    + "\n state: "
                    + str(message["channel"]["state"])
                    + "\n"
                )
                return True, result
            else:
                result = "wrong channel-id -> " + message["channel"]["id"]
                return False, result
        else:
            result = "wrong type -> " + message["type"]
            return False, result
    else:
        result = "messages not eual" + message
        return False, result

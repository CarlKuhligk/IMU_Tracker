import websocket
import json


def test(c1):
    message1 = json.loads(c1.recv())

    if message1["type"] == "update":
        if message1["device"]["id"] == "0":
            return True, 4
        else:
            # wrong channel-id
            return False, 0
    else:
        # wrong type
        return False, 0

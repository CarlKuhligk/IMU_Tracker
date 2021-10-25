import websocket
import json


def test(ws):
    ws.send("empty")
    message = json.loads(ws.recv())

    if message["type"] == "response":
        if message["id"] == "30":
            return True, message["id"]
        else:
            return False, message["id"]
    else:
        # wrong type
        return False, 0

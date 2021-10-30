import websocket
import json


def test(ws):
    wsMsg = {"type": "subscribe", "device_id": "0", "subscribe": "true"}
    ws.send(json.dumps(wsMsg))
    message = json.loads(ws.recv())

    if message["type"] == "response":
        if message["id"] == "24":
            return True, message["id"]
        else:
            return False, message["id"]
    else:
        # wrong type
        return False, 0

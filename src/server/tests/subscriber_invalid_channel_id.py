import websocket
import json


def test(ws):
    wsMsg = {"type": "subscribe", "device_id": "9846465464737435743764545324457"}
    ws.send(json.dumps(wsMsg))
    message = json.loads(ws.recv())

    if message["type"] == "response":
        if message["id"] == "23":
            return True, message["id"]
        else:
            return False, message["id"]
    else:
        # wrong type
        return False, 0

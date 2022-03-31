import websocket
import json


def test(ws):
    wsMsg = {"type": "data", "value": [1.75, 2.01, 3, 4, 5, 6, 7.98]}
    ws.send(json.dumps(wsMsg))
    message = json.loads(ws.recv())

    if message["type"] == "response":
        if message["id"] == "22":
            return True, message["id"]
        else:
            return False, message["id"]
    else:
        # wrong type
        return False, 0

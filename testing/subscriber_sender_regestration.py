import websocket
import json


def test(ws):
    wsMsg = {
        "type": "sender",
        "apikey": "23b651a79c9a5136d4751e6df9659ea15ed9df4768c211ede558d1ebd3b0c5bd",
    }
    ws.send(json.dumps(wsMsg))
    message = json.loads(ws.recv())

    if message["type"] == "response":
        if message["id"] == "29":
            return True, message["id"]
        else:
            return False, message["id"]
    else:
        # wrong type
        return False, 0

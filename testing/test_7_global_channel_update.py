import websocket
import json


def test(ws, c1, c2):
    message = json.loads(ws.recv())
    message1 = json.loads(c1.recv())
    message2 = json.loads(c2.recv())
    if message == message1 and message == message2:

        if message["type"] == "update":
            if message["channel"]["id"] == "16":
                return True, 4
            else:
                # wrong channel-id
                return False, 0
        else:
            # wrong type
            return False, 0
    else:
        # messages not eual
        return False, 0

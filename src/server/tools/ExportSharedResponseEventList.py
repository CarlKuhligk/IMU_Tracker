from cmath import log
import re
import os.path


phpResponseList = open(os.path.dirname(__file__) +
                       '/../php/ResponseList.php', "r").read()
phpEventList = open(os.path.dirname(__file__) +
                    '/../php/EventList.php', "r").read()

regexResponse = r"((?<=R_)\w+)\",\s(\d+)"
regexEvent = r"((?<=E_)\w+)\",\s(\d+)"

resultCSVContent = ""
totalElements = 0

print("Start extracting")

# processing response list
matches = re.finditer(regexResponse, phpResponseList, re.MULTILINE)

print(f" Responses:")
for matchNum, match in enumerate(matches, start=1):
    name = match.group(1).replace("_", " ")
    id = match.group(2)
    totalElements += 1
    resultCSVContent += f"R,{name},{id}\n"
    print(f"-> ID: {id} Name: {name}")

# processing event list
matches = re.finditer(regexEvent, phpEventList, re.MULTILINE)

print(f"\n Events:")
for matchNum, match in enumerate(matches, start=1):
    name = match.group(1).replace("_", " ")
    id = match.group(2)
    totalElements += 1
    resultCSVContent += f"E,{name},{id}\n"
    print(f"-> ID: {id} Name: {name}")

sharedFile = open((os.path.dirname(__file__) +
                  "/../../SourceResponseEventList.csv"), "w")
sharedFile.write(resultCSVContent)
sharedFile.close()

print(f"{totalElements} Elements extracted!\n\n")

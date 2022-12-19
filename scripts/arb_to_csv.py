import json
import csv

input = "lib/l10n/ru.arb"
output = "output/ru.csv"

# Open the .arb file
with open(input, "r") as file:
    # Parse the JSON content
    data = json.load(file)

# Open the .csv file for writing
with open(output, "w") as file:
    # Create a CSV writer object
    writer = csv.writer(file)

    # Write the header row
    writer.writerow(["key", "description", "en"])

    # Iterate through the data and write each row
    for key, value in data.items():
        # Check if the key starts with "@"
        if key.startswith("@"):
            continue
            # Set the description to the key and the value to an empty string
            description = key
            en_value = ""
        else:
            # Check if the value is a dictionary or a string
            if isinstance(value, dict):
                # Get the description from the dictionary
                description = value.get("@", {}).get("description", "")
                en_value = value.get("", "")
            else:
                # Set the description to an empty string
                description = ""
                en_value = value
        writer.writerow([key, description, en_value])

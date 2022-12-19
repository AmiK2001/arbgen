import csv

en = "output/en.csv"
ru = "output/ru.csv"
output = "output/merge.csv"


# Create an empty dictionary to store the data
data = {}

# Open the first .csv file
with open(en, "r") as file:
    # Create a CSV reader object
    reader = csv.reader(file)

    # Skip the header row
    next(reader)

    # Iterate through the rows and add the data to the dictionary
    for row in reader:
        key = row[0]
        value = row[1:]
        data[key] = value

# Open the second .csv file
with open(ru, "r") as file:
    # Create a CSV reader object
    reader = csv.reader(file)

    # Skip the header row
    next(reader)

    # Iterate through the rows and update the dictionary with the data
    for row in reader:
        key = row[0]
        value = row[1:]
        # Update the "description" column with the "description" column from the second file
        data[key][0] = value[0]
        # Add the "ru" column to the end of the value list
        data[key].append(value[1])

# Open the output .csv file for writing
with open(output, "w") as file:
    # Create a CSV writer object
    writer = csv.writer(file)

    # Write the header row
    writer.writerow(["key", "description", "en", "ru"])

    # Iterate through the data and write each row
    for key, value in data.items():
        # Use indexing to access the elements in the list, with a default value of "" if the index is out of range
        description = value[0] if 0 < len(value) else ""
        en = value[1] if 1 < len(value) else ""
        ru = value[2] if 2 < len(value) else ""
        writer.writerow([key, description, en, ru])

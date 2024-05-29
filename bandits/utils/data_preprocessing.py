import datatable as dt

def _transform_age(age):
    if dt.isna(age):
        return 0

    for decade in range(1, 10):
        if age == f"{decade}0 - {decade}9":
            return decade

    if age == "90+":
        return 9

    raise RuntimeError(f"Invalid age: {age}")

def _transform_portfolio(portfolio):
    if dt.isna(portfolio) or portfolio.lower() == "unknown":
        return 0

    if portfolio == "$100,000 - $249,999":
        return "250K"
    elif portfolio == "$250,000 - $499,999":
        return "500K"
    elif portfolio == "$500,000 - $999,999":
        return "1M"
    elif portfolio == "$1,000,000 - $1,999,999":
        return "2M"
    elif portfolio == "$2M+":
        return "2M+"

    raise RuntimeError(f"Invalid age: {portfolio}")

def load_data(path):
    data = dt.fread(path)

    # Remove users for whom there is no interaction data
    data = data[data["n_interactions"] > 0]

    # Add age feature
    data["age"] = data["age"].apply(_transform_age)

    # Convert to pandas
    return dt.fread(path).to_pandas()


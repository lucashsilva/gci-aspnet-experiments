import pandas as pd
import matplotlib.pyplot as plt

def describe(filename):
    columns = [1, 2]
    percentiles = [.9, .99, .999, .9999, .99999, .999999]
    names = ['status', 'request_time']
    sort_column = 'request_time'

    df = pd.read_table(filename, delimiter=';', names=names, usecols=columns, skiprows=5000)
    df['request_time'] = 1000 * df['request_time']
    # df['upstream_response_time'] = 1000 * df['upstream_response_time']
    df.sort_values(sort_column, ascending=True)
    print(df.describe(percentiles))

describe('../results/al_gci_1.log')
describe('../results/al_nogci_1.log')
import pandas as pd
import numpy as np
import random
import plotly.graph_objects as go
import plotly.express as px

import dash
from dash.dependencies import Input, Output
import dash_core_components as dcc
import dash_html_components as html
import dash_bootstrap_components as dbc
import dash_table

days = 300
initialinventory = 20
restockProb = .30
restockAmt = 5
distribution = "Poisson"
randomSeed = 533

random.seed(randomSeed)
beginningofday = [0] * (days+1)
endofday = [0] * days
missed = [0] * days

demands = random.choices(np.arange(0,9), 
                         k=days)
restockProbs = [restockProb, 1-restockProb]
restock = random.choices([restockAmt, 0], 
                         weights=restockProbs,
                         k = days)

beginningofday[0] = initialinventory
for i in np.arange(days):
    if demands[i] > beginningofday[i]:
        missed[i] = demands[i]-beginningofday[i]
        endofday[i] - 0
    else:
        endofday[i] = beginningofday[i] - demands[i]
        
    beginningofday[i+1] = endofday[i] + restock[i]
    
    
d = {'Day': np.arange(days)+1, 
     'BegOfDay':beginningofday[:-1], 
     'EndOfDay':endofday, 
     'Missed':missed}

SIMULATION = pd.DataFrame(data = d)
linePlot = go.Figure(data = go.Scatter(x = SIMULATION["Day"], y = SIMULATION.BegOfDay))





app = dash.Dash(__name__, external_stylesheets=[dbc.themes.BOOTSTRAP])

app.layout = html.Div([
    html.H1("Inventory Control Simulation"),

    dbc.Row(children = [
        dbc.Col(
            width = 3,
            children = [
                html.Div([            
                    html.Header("Number of days"),
                    dcc.Slider(
                        id      = "days",
                        value   = 100,
                        min     = 30,
                        max     = 365,
                        marks   = {
                            30:"30 days",
                            365:"365 days"
                        },
                        step    = 1
                    ),

                    html.Header("Initial inventory"),
                    dcc.Slider(
                        id      = "initialinventory",
                        value   = 20,
                        min     = 0,
                        max     = 100,
                        step    = 1
                    ),

                    html.Header("Probability of overnight restock"),
                    dcc.Slider(
                        id      = "restockProb",
                        value   = .30,
                        min     = .01,
                        max     = .99,
                        step    = .01
                    ),

                    html.Header("Restock amount"),
                    dcc.Slider(
                        id      = "restockAmt",
                        value   = 6,
                        min     = 1,
                        max     = 20,
                        step    = 1
                    ),

#                     html.H4("Distribution"),
#                     dcc.RadioItems(
#                         id = "distribution",
#                         options = [
#                             {'label': 'Poisson', 'value': 'Poisson'},
#                             {'label': 'Uniform (0-8)', 'value': 'Uniform (0-8)'},
#                             {'label': 'Uniform (3-5)', 'value': 'Uniform (3-5)'}
#                         ],
#                         value = "Poisson"),
                    
                    html.Header("Random # seed"),
                    dbc.Input(
                        id = "randomSeed",
                        value = 533,
                        type = "number"
                    )
                ])
            ]
        ),
        
        dbc.Col(
            width = 9,
            children = [
                html.Div(children = [
                    html.Header("Variable:"),
                    dcc.RadioItems(
                        id = "lineVar",
                        options = [{"label":"Beg. of Day", "value":"BegOfDay"},
                                   {"label":"End of Day",  "value":"EndOfDay"},
                                   {"label":"Missed",      "value":"Missed"}],
                        value = "BegOfDay"
                    ),
                    dcc.Graph(id = "linePlot"),
                    dcc.Graph(id = "histogram")
                ])
            ]
        )
    ]) 
])

    

def create_timeplot(df, y):
    fig = px.scatter(df, x='Day', y=y)

    fig.update_traces(mode='lines')
    
    fig.update_xaxes(showgrid=False)
    
    return fig

def create_histogram(df, x):
    fig = px.histogram(df, x = x, nbins = 30)
    
    return fig


@app.callback(
    [Output("linePlot", "figure"),
     Output("histogram", "figure")],
    [Input("days", "value"),
     Input("initialinventory", "value"),
     Input("restockProb",      "value"),
     Input("restockAmt",       "value"),
     Input("randomSeed",       "value"),
     Input("lineVar",          "value")]
)
def run_simulation(days, initialinventory, restockProb, restockAmt, randomSeed, lineVar):
    random.seed(randomSeed)
    beginningofday = [0] * (days+1)
    endofday = [0] * days
    missed = [0] * days

    demands = random.choices(np.arange(0,9), k=days)
    restockProbs = [restockProb, 1-restockProb]
    restock = random.choices([restockAmt, 0], 
                             weights=restockProbs,
                             k = days)

    beginningofday[0] = initialinventory
    for i in np.arange(days):
        if demands[i] > beginningofday[i]:
            missed[i] = demands[i]-beginningofday[i]
            endofday[i] - 0
        else:
            endofday[i] = beginningofday[i] - demands[i]

        beginningofday[i+1] = endofday[i] + restock[i]


    d = {'Day': np.arange(days)+1,
         'BegOfDay':beginningofday[:-1],
         'EndOfDay':endofday,
         'Missed':missed}

    SIMULATION = pd.DataFrame(data = d)    

    return(create_timeplot(SIMULATION, lineVar),
           create_histogram(SIMULATION, lineVar))



if __name__ == '__main__':
    app.run_server(debug = True)

# Introduction: COVID-19 and EpiSim

In February 2020, the team at VSP began work on an extension to MATSim which soon became known as "EpiSim."

YY reference which paper/papers?

The EpiSim model was a novel hybrid of the agent-based microsimulation model MATSim and epidemiological infection progression models. New versions of the combined model were being released, tested, and run multiple times per week in the frenetic early days of the COVID-19 pandemic in Europe. This produced massive amounts of data from literally hundreds of model simulations -- often daily.

It quickly became apparent that the team needed a way to compare all of these runs in a visual manner, and also to be able to convey salient results to decisionmakers and the public. A web-based solution was an obvious choice for both use cases, but the many problems we encountered in modifying or enhancing MatHub made us unsure that a heavyweight client/server solution would be able to keep up with the team's needs.

We decided to take an unusual approach for such a large undertaking, which leveraged the investments already made in web-based visualization technologies but jettisoned all of the back-end servers: we rapidly built what is called a "Single Page Application" (SPA) that was a completely self-contained website, with no back-end server at all. All of the website code and all of the data files would be served "statically" from a simple web server.

Eventually the size of the site expanded and the data storage for model results was moved to a dedicated file server, but otherwise the overall architecture remained constant and the site continues in operation today.

This approach proved successful in meeting our team's needs, and is described fully in this chapter.

The COVID-Sim website is available at <https://covid-sim.info>

## How websites are built: clients and servers

As described earlier in YY, web sites always consist of the content which is loaded into a browser, known as the "client", and the back-end servers which the client connects to. In the simplest case, a user points to a URL, and the browser loads the HTML index file at that location along with any other static files referenced in the HTML. This is known as a "static" website, as the web server doesn't need to do any dynamic processing to serve the request; it simply delivers the requested files over the network.

Of course, much more complex arrangements are also possible. The web server can run code or scripts which generate part of the page dynamically, can call APIs which pull data from other servers or databases, and so on. These are known as "dynamic" sites, and for example our MatHub project used this arrangement.

## Single Page Applications

As early as 2003 [YY reference SPA page on wikipeda -- better ref?], the concept of a single-page application which runs Javascript code in the browser was already in existence. These types of sites run Javascript locally in the browser to transform the page contents that arrive from the web server. This is often done to make a page feel more interactive or more like a native desktop app. Some of the most popular websites in existence, such as Twitter and Facebook, employ this architecture.

Contrast this with the more traditional client/server architecture that frameworks such as PHP or Ruby on Rails employ: a network request from a browser client results in code running on the server which then builds and returns an HTML page to the client.

Crucially, the SPA approach allows for user interactions to modify the content of a page without requiring a round-trip data request to a support server. Once the page is loaded, the SPA is ready. Further API calls are allowed, of course, which means data can be queried from external sources as needed. But the essential Javascript code which drives the website functionality is delivered to the browser and runs there.

# The EpiSim Single Page Application

This approach seems ideal for our needs, as we didn't want to be modifying server code every time a new version of the EpiSim model added new parameters.

Thus we created our first simple Vue-based YY single page application which loaded a basic HTML template, a zipfile with all summary model run outputs, and the view logic to link a few slider bars with pandemic intervention approaches with some resulting line charts of pandemic progression over time.

YY show pic of v1

The initial interventions being considered were: "Close Public Transit", "Close Workplaces", "End Social Activities", and "End All Other Activities". Each of these interventions could be user-selected at a given timepoint, measured from "Never" to 10, 20, or 30 days after the start of the pandemic. Notably, these were the early days before many other measures such as mask mandates, school closures, or eliminating air travel were available -- and vaccination programs were still far off in the future.

The site was operational internally in a matter of days, and made public on March 30, 2020.

The first versions of the site were produced rapidly and were quite crude, for example with no overall site navigation and almost nothing in terms of exposition. As the project (and pandemic) continued, more model versions were developed and each previous version was archived (but accessible) for reference and comparison.

# Cataloging model input parameters and the resulting model outputs

As EpiSim gained complexity, so did the model output portal. The number of simulations ballooned to hundreds or thousands of runs per week, and new versions of the model itself were developed to improve results and to answer decisionmaker questions about the latest turns of the pandemic -- whether that be mask mandates, school closures, vaccination strategies, boosters, etc.

To keep up with this churn, the data visualization strategy was also constantly modified. In particular, a new way of mapping the multitude of inputs to the run identification numbers ("Run IDs") was developed, as the initially small handful of four slider bars was quickly replaced by groups of numerous buttons grouped into logical sets, every combination of which would reference one specific model run.

The combinatorial nature of these options made it imperative that we adopt an automated process for identifying model outputs, as well as a way to navigate between different versions of the model itself.

# Describing simulations using YAML

The solution is comprised of two pieces of data for each batch of model runs:

First, a simple table that links the run identification numbers with the specific input parameter values for every parameter in the model. So for a batch of runs testing four mask strategies and two school closure strategies, 4x2 is eight combinations of parameters, thus the table includes eight rows. Each row assigns a Run ID and the value of the two hypothetical parameter values. In reality there are always far more than eight combinations; often 768 or 1,024 different permutations of a dozen parameters were tested, all batched together in a nightly run on the University high-performance compute cluster. This lookup table is stored as a simple text file in CSV format.

Second, for the display of available options to users of the EpiSim dashboard, a human-friendly mapping between option groups, variable names, and values is needed.

Most variables in EpiSim are either general in nature, affecting the entire simulation; or time-based, occurring on specific dates or "X days after" the start of the simulation. This leads to a natural grouping of parameters which makes the many user interface options more digestible for non-experts in EpiSim.

The EpiSim parameters themselves are usually numeric or categorical; each variable can have multiple values that also have a human-interpretable meaning. For example the percentage of people wearing masks on transit; or the types of masks being worn (N95, surgical, none).

Capturing all of this information in a definable, repeatable format for use in the user interface required something more structured than the simple lookup table above.

For this, we use a common configuration file format known as YAML ("Yet another markup language"). The YAML standard is defined at YY.

YAML excels at describing sets of key:value relationships. It is human-readable and computer-parseable; these traits lead to YAML being a common format for specifying configuration information.

YY Ask Christian - how does this work

For a batch of EpiSim runs, the operator of EpiSim produces the lookup table with the specific model parameters and a YAML file containing the metadata that describes in human terms how the variables will be presented to the user in the dashboard.

An example YAML file is below: this is abbreviated for clarity. More complex model runs have more sections and more variables defined.

YY

# Retrieving model results

The final piece of the puzzle is the storage and retrieval of the actual model results.

A batch of simulation runs produces summary outputs for every combination of model parameters. Those outputs are identified by the Run ID defined above, and they are compressed into a single .ZIP format file archive. The contents of the .ZIP file vary based on what version of the model was run: early versions only included YY, while later versions added additional outputs such as YY.

Thus a full batch output, ready for display in the COVID-Sim website, includes:

- info.txt: the table of simulation Run IDs along with the specific values for every model parameter used; one row per simulation.
- metadata.yaml: the collection of descriptive names for each variable and their groupings
- summary zip files: a folder containing one .ZIP file for each simulation.

These files are stored on the departmental file server in hierarchical folders, organized by run date, city, and sometimes other categories.

The COVID-Sim website maps the requested URL directly to the file structure on disk: so for example, http://covid-sim.info/2021/11/05/example-run displays results stored in the 2021/11/05/example-run folder on the file server.

# Architecture

With all these pieces in place, the unique overall architecture of the EpiSim data visualization portal emerges:

- An "SPA" single page application, based on Vuejs and hosted on a static website hosting provider
- Hierarchical file storage on a university departmental file server, with data for all published runs available via HTTP. Each run is stored in its own folder, and contains:
  - Automatically-generated configuration files, produced when the EpiSim simulation runs are set up, which describing the specific combinations of input parameters that are to be run.
  - A lookup table which maps each combination of input parameters to a specific output dataset
  - Zipped output files containing the summary data for each simulation run identifiable in the above lookup table.

... YY

# Animations of infection progression in Berlin

A second goal of the site was to be an external-facing portal for educating decisionmakers, the media, and the public. Internal analysts much appreciated the ability to compare results of model runs by flipping switches and sliders and seeing how the model output graphs reacted. But as the team took results to non-experts, we identified the need to take a step back and create a visual representation of how the model actually worked.

The agent-based model is based on the daily activities and movements of every population member, interacting with each other, spreading the infection when contagious, and then having the disease progress.

This is well-suited to an animation of the agents moving through time and space. Such an animation was included between versions 2 and 4 of the EpiSim model itself. It depicts the "do nothing" scenario for Berlin: how the COVID-19 pandemic would proceed through Berlin and the surrounding areas if no measures at all were taken.

YY some screenshots of the pandemic animation

The infection status of each agent is represented by color: susceptible, infected, contagious, sick, seriously sick (hospitalized), critical (intesive care), and recovered. Their motions can be seen over the course of a day and over the 90-day course of the pandemic simulation. Any specific day in the simulation can be chosen from a panel to see the infection status of the population on that day.

The exponential nature of the pandemic is very clearly illustrated in this manner.

YY Based on feedback, this animation was helpful in the spring of 2020 to help describe how the model worked.

A second animation was added later that removed the daily back-and-forth motion of agents on individual trips, and simply showed the status of agents at their home locations, over the course of the 90-day simulation.

# Informing decisionmaking with comparison dashboards

YY How did government get involved ?

Over the twisting course of the COVID-19 pandemic, the EpiSim model acquired new capabilities. Each passing month introduced new questions:

YY timeline:

- masks
- schools
- lockdowns
- events
- dining
- sports
- vaccination
- external travel
- variants
- boosters

And the model dashboard grew longer and longer to display new graphs of the salient questions of the day. This iterative process was entirely needs-based: as the team was asked (or anticipated) new questions

# User feedback

# Iteration and further work

# Discussion

Having confirmed the utility and capabilities of a fully browser-based data visualization approach for three individual project portals, we then set out to generalize the method. An entirely generic data visualization platform is inherently more difficult than a project portal, as every researcher investigates widely disparate questions and will be focusing on completely different outputs. Where one researcher may be using MATSim to predict future dynamic-response shared taxi vehicle flows, another is doing emergency-response evacuation planning, or emissions reduction through increased transit ridership efforts. The tool needs to be extremely flexible.

This chapter describes **SimWrapper**, an open-source web-based data visualization platform we developed with the goal that it be useful for anyone working with MATSim outputs or even outputs from other data-intensive microsimulation models.

# Overview: SimWrapper, in a nutshell

Many design questions were already settled in the aforementioned research YY.

SimWrapper, in a nutshell:

- (1) is a static website that runs client-side javascript in the form of a "single page application", a common approach in current web development that is compatible with all modern web browsers;
- (2) supports network-based file storage for public- and/or group-accessible shared data files (model runs), but has no other back-end server requirements and can run completely locally if no network file storage is available or needed;
- (3) allows the user to navigate through their local filesystem or shared network storage of model runs to view results that are saved in a specific folder, rather than a database-centric approach. This matches the design of MATSim and other simulation models which produce collections of output files by default;
- (4) provides a collection of data visualization archetypes that are each appropriate for displaying a certain type of data, for example various statistical chart types (bars, lines, area, pie), geographic data viewers supporting road and transit network link data, area aggregation ("choropleth" and "spider") maps, XY coordinate plots, and many more;
- (5) can combine all of these disparate components into cohesive dashboards that the user can lay out in a flexible manner, using small declarative configuration files. These configurations can be applied across multiple projects or simulation runs;
- (6) is GDPR (General Data Protection Requirement) compliant by default, due to the complete lack of any user tracking, data uploads, servers, advertising, or any other privacy-compromising misfeatures. SimWrapper is not a product for sale; it is an open research platform, and can therefore forego these modern nuisances.

The following sections explore the design of SimWrapper in more detail.

**YY diagram of design**

# Reuse of existing framework and components

The starting point for SimWrapper was the PAVE project website described in section YY. This "single page application" approach involves selecting a curated set of javascript infrastructure libraries for common needs, and then writing bespoke code for our specific use case and the "glue" between the components.

Our experience with PAVE led us to select existing Javascript libraries for the following:

- User interface interaction: the "Vue" framework YY is the primary glue that links the page layout with user interactions such as mouse clicks, running code when user-initiated events occur
- Data loading: Most MATSim outputs are either tabular text files in CSV format, or compressed XML files with explicit schemas. The Papaparse and Fast-XML-Parser libraries handle loading these two data formats
- Charting: the PAVE site included statistical charts such as bar, line, pie, and scatter plots, and used the Plotly javascript library. Plotly is very easy to use but not as feature-rich as some other choices; see below YY for updated capabilities
- Geographic data on maps: our initial efforts using the Mapbox javascript library led us to the more performant Deck.gl collection of map-based visualizations.
- Animation: Three.js is a very flexible 3D animation library that is used for PAVE vehicle animation visualizations.

All of these libraries share compatible open-source licenses, and are included in SimWrapper under the terms of those licenses.

# Modifications necessary

Direct user feedback, described in detail in section YY, allowed us to map out a set of changes and improvements for the generic tool. In summary, changes were needed in the following categories:

- Performance. The network link viewer in particular was slow to load datasets for large simulations. This was not a problem for PAVE or AVÖV because the study areas were less populated.

- Flexibility. Each of the data visualization components needed to be made much more flexible. For example, the PAVE link viewer assumed that input data was specified by time period, whereas a generic tool needs to depict any sort of data.

- Output traversal. While PAVE had a hard-coded set of alternatives that could be browsed in a simple manner, a generic tool needs some sort of model run traversal capability; a way to browse the hierarchical file storage available.

- Stability and resilience. The PAVE site included almost no error message reporting or helpful debugging infrastructure, because expert analysts carefully crafted the inputs for each alternative. A generic tool needs to be tolerant of user mistakes and helpful in guiding the user when inputs are lost or malformed.

- Better defaults plus configurability. We do not intend to replicate a full-featured desktop application, of which there are many in the Geographic Information System (GIS) realm. Rather, users expressed a desire for a set of clear, curated defaults that have some configurability. For much more advanced configuration, a professionally-developed package such as QGis is likely more appropriate.

### Audience

The PAVE website was intended to be public-facing: both agency staff and actual members of the public could navigate the site. It presented a small set of YY six alternatives, depicting the same visualizations for each alternative.

SimWrapper could be public facing, but is predominantly used in its current form by researchers and professional analysts at public agencies.

YY

# Accessing files through a web browser

The use case of file storage via departmental file server is well-explored and very functional, as expressed in the project websites for AVÖV, PAVE, and COVID-Sim.

A key difference between the earlier project websites and SimWrapper is the need to "meet the users where they are" -- in other words, we cannot rely on there being a departmental file server with a public API endpoint serving data files. One of the primary feedback elements from the initial MatHub implementation described in chapter YY was that it was too onerous to upload model run outputs to a second server system before being able to view or analyze anything. In addition to being wasteful of space (and MATSim outputs can be gigabytes in size!), it is time-consuming.

For regular users in the middle of their research workflow, something else is needed. Most of our internal users run simulations either on their personal laptop/desktop machines, or on the university compute cluster, which has extensive attached storage but no public-facing access via the web. Furthermore, these runs are often not intended to be immediately publicized.

Thus we explore several avenues for enabling users to view their outputs, described here.

## How SimWrapper access files via HTTP

SimWrapper is designed to allow browsing of files from administrator-defined HTTP URLs, which represent the root of the file storage for that project. For example, the PAVE project datasets are all stored on the VSP public file server at the URL

<https://svn.vsp.tu-berlin.de/repos/public-svn/matsim/scenarios/countries/de/berlin/projects/pave/website/>

That URL is the defined "root" of the project; all of the project dashboard configurations, model outputs, and processed data files exist in various subfolders below that location. The PAVE website at https://vsp.berlin/pave is set up to read files from that base URL. (But refer to section YY for a discussion of CORS configuration, which is necessary to allow one website to read the files stored on another.

SimWrapper elevates this to allow multiple configured root filesystems; the public VSP file server is one such root, but others can also be configured and are displayed on the home page of SimWrapper. Each root is expected to provide HTTP directory access to this storage: SimWrapper needs to be able to _view directory listings_ and _retrieve file contents_. SimWrapper never writes any files anywhere; it is read-only.

## Local files on a personal laptop/desktop

This design presents a problem for local files: By design, all web browsers explicitly forbid file-system access from any websites by default. This default is certainly a good default; no one wants any random website to start sniffing around their home directory.

But in our case this is not any random website: we _want_ SimWrapper to see the files in some of our local folders. How can this be accomplished?.

After several explorations including raw HTML files opened directly, arcane experimental browser flags (always vendor specific!), and other less fruitful avenues, the one method that consistently works for all browsers is as follows: for browsing local files on a machine, first start up a small helper application which is itself a simple HTTP server. This tiny server responds to HTTP requests and delivers the directory contents requested. The server listens on "localhost", i.e. your own computer, generally on port 8000. So the full URL is <http://localhost:8000/>.

Once this is set up and running, this HTTP endpoint can be accessed in SimWrapper just like any other external file storage. SimWrapper knows be default to look for files at URL <http://localhost:8000>.

As part of this research we wrote a very small Python library which provides this server. Any machine with Python 3.x installed can run `pip install simwrapper` to install this mini file server, and then run it by navigating to their data folder and running the command `simwrapper serve`. That includes all of the server components and configuration needed to server files to SimWrapper.

Some configuration notes:

- The local HTTP server will only serve the files from inside the working directory in which it is started, including any subfolders. No other folders on the user's machine are exposed.
- The computer's operating machine has default firewall and router rules that will generally prohibit any outside access from other computers on the LAN or the Internet. This can be modified; see YY
- Some configuration details for the server that are important for our use case: we must enable access from websites at different URLs using "CORS" configuration headers; see YY
- Some browsers (Safari, and now recent builds of Chrome) sometimes block access to localhost sites or http sites (vs. https sites), see discussion at YY
- Every language framework already includes some sort of "Tiny HTTP Server" library for just these types of uses: in Python it is in the `http.server` library, in Java there is the Jibble SimpleWebServer. Our `simwrapper` python tool leverages the existing Python infrastructure.
- We also wrote a java version, published as `mini-file-server.jar` for users who are more comfortable running Java-based software than Python.

The Python tool including source and user documentation is currently available at <https://pypi.org/project/simwrapper/>.

The Java tool is currently available at <https://github.com/simwrapper/mini-file-server>

### Data security and privacy

With this setup, the SimWrapper site itself is loaded from the Internet, but once loaded, the user's data never leaves their computer. SimWrapper is an entirely client-based system with absolutely no upstream server. The javascript runs in the users' browser, accessing files available on localhost only -- also on the user's own computer. Nothing leaves the browser. If there are privacy or confidentiality issues with model outputs, SimWrapper can still be used for analysis in this "localhost" mode.

## Files residing on the university compute cluster, accessed via SSH

This local-http-server paradigm can be extended to access files on any remote university computer cluster using the SSH ("secure shell") protocol.

SSH is usually the protocol (and command) used to log into remote systems. There is a parallel command which allows "mounting" the remote file system using the SSH protocol. The remote files are mapped to a folder on the user's system; once mounted, the user can browse the files inside that folder as if they were local files (but generally more slowly, depending on network throughput conditions).

- Linux users can install the command `sshfs` to add this capability;

  - once installed, a command similar to `sshfs username@cluster.math.tu-berlin.de:/net/myfiles cluster` will mount the remote folder `/net/myfiles` to my local folder `cluster`. You would change the username, URL, and folder names to match your situation.
  - `sudo umount cluster` or similar to unmount.

- YY MacOS is similar to Linux but requires installing the sshfs fuse driver first

- YY Windows users have many options for FUSE-based sshfs support, this repo is nice one <https://github.com/billziss-gh/sshfs-win>

## Files residing on another machine on the local LAN network

A challenging use case presented by users is one or more central "modeling server" machines on the local LAN, where most runs are performed and which contain the simulation outputs.

The aforementioned localhost-based HTTP server does not work in this situation, because a user sitting at their computer, opening the Internet-based SimWrapper website, trying to read files served via localhost on the modeling server, will always be blocked by browser security measures. After many hours trying to find a way to sneak around these restrictions, we accepted that this security measure is working as designed, and we need a different approach.

The reason this approach is blocked is because the SimWrapper website is hosted on a secure "HTTPS" server, while the localhost files must be served without encryption using HTTP. Setting up an encryption certificate is difficult because internal LAN machines don't typically have world-findable DNS entries. This combination of secure and insecure content is blocked by all browsers.

A workaround is to serve the files and the site from the same file server, instead of using the Internet-based SimWrapper that is hosted at vsp.berlin. We are already asking users to run a small file server to access their local files, thus extending that file server to also serve the necessary javascript and HTML is a natural extension.

And this is what we have done: a special mode is added to the `simwrapper` python tool named `simwrapper here`. Now the little server will serve both the file contents of the folder in which it is started, _and_ the SimWrapper website itself.

The user runs `simwrapper here` on the file server instead of `simwrapper serve`, _noting the full URL printed in the console_, and then on their personal computer browses to that URL instead of to vsp.berlin/simwrapper. In this manner, the site and any local files stored on that server are made available, together.

This also implies that SimWrapper can be used completely offline once it is installed.

## Special case: Chrome and the "File System Access API"

Google Chrome and a subset of other browsers based on the Chromium codebase implement an experimental API known as "File System Access API". This is not part of the official Web specification, and it may never be adopted by other browser vendors.

But for users running Google Chrome, this experimental API provides another avenue for accessing local files, one which completely eliminates the need for the local file server approaches above.

This is considered "progressive enhancement," or in other words, adding features to the website when the browser is identified as supporting them.

On Chrome, users will see an additional element on the main page of SimWrapper, a button allowing them to grant access to local files. The browser will open a standard folder-picking dialog followed by a warning that granting this permission will allow the SimWrapper site to view the files in that folder. Et Voíla, that is exactly what we need.

Once permission is granted, local files are immediately visible without any additional configuration. This permission can be revoked and may be re-requested every time the browser restarts.

YY show browser grant access dialog

# Converting purpose-built visualizations into generic data viewers

The underlying infrastructure -- the build system, the user interaction libraries, and the choice of off-the-shelf components -- was more or less complete after the PAVE, AVÖV, and COVID-Sim projects were operational. But the specific views needed a great deal of retooling to make them useful in a generic manner.

This section describes some of the most challenging aspects of this process of genericizing SimWrapper.

### Link viewer

The link viewer was originally scoped to display link volumes only, such as a typical "bandwidth plot" commonly used in travel modeling. Even for PAVE this was short-sighted, as the project team quickly found other uses for the viewer such as link-based emissions.

Two critical updates made for SimWrapper are (1) the removal of the assumption that the data inputs will always have time period data in the columns, plus a summary "grand total" column; and (2) that colors and widths must be configurable, preferably separately.

These changes are now part of SimWrapper -- see YY for a typical plot.

YY show a bandwidth plot

User testing shows that a great deal more is still necessary to meet user expectations. Data filters and configurable hovers are two of the most-requested enhancements.

YY user testing

### XY Hexagon plots

Much data is not link-based, even for transport simulations. Activity locations, home locations, pickups and dropoffs for transit and taxi modes, all have coordinates associated with them but are not necessarily attached to specific links.

A new visualization type, the "XY Hexagons" plot, depicts these types of data by aggregating them into user-definable hexagonal buckets. The number of points inside the hexagons corresponds to a color or height; this is user-configurable.

YY show XY Hexagon plot

The default MATSim output `output_trips.csv` includes this type of data, and is automatically viewable without any configuration at all if it is present in a SimWrapper data folder.

### Calculation tables

YY Show PAVE example run output with Sankey, numbers, etc

# Dashboards: combining visualizations to support decisionmaking

A dashboard is a page laid out with multiple charts, plots, and visualizations all together. The layout is defined in a YAML file that contains the types of plots and their configuration parameters, all in one place.

YY SHOW Dashboard
_Dashboards usually show several at-a-glance summary metrics._

In SimWrapper, a folder containing any number of `dashboard-*` YAML files will display the dashboards in addition to the usual folder browser view. When multiple dashboard YAML files exist, they will be shown as multiple navigation tabs on the page.

- The layout consists of a set of named **rows**. The row name themselves are not shown anywhere, they are there to help organize the file.

- Each `row` consists of a list of chart objects. By default, all objects in the row will be laid out horizontally from left to right, in equal widths. This can be configured.

- Finally, each element in a row has specific properties that define the actual chart or visualization that will be displayed.
  - **type** The chart or plot type, e.g. `pie`, `bar`, `flowmap`, etc. See the individual chart docs for all available plots.
  - **title** The name of the plot
  - **description** A brief description (optional)
  - **width** One can set _relative widths_ by adding the `width: [number]` property. Charts have a default width of 1. Thus in a row with 3 charts, if the width of the first object is 2, then [2+1+1] means the first object fills 50% of the row, and the remaining two objects fill 25% each. (optional)
  - **props** The set of configuration settings for this chart, such as the dataset to load, which columns to use, etc.
  - _The chart type determines the set of valid properties!_

This system of defining dashboards in configuration has been used to great effect in many internal studies

YY Show Hamburg ? Düsseldorf?

# Project traversal and organizing outputs

Project organization for MATSim is left up to the user: there is no central database or general organizing principle which analysts must adhere to. Thus different teams will find different ways to store their data: by project, by date, by scenario type, etcetera. Some may use a very flat structure with a defined naming scheme, while others will use deeply nested folders to keep things tidy.

Because of this flexibility in MATSim, SimWrapper needs to be able to handle deeply hierarchical storage as well as extremely large folders full of runs.

There is much more room for improvement here, but the basic format of a file and directory browser, which allows the user to "drill down" into subfolders, will be part of any solution.

## Project-level configuration

Users often expressed interest in setting up standardized output summaries in the form of dashboards, specific link- or xy-data comparison plots, etc., and to use those for every model run for that project.

This is addressed by having a `simwrapper` folder in or above the output-data folders. The simwrapper folder contains any common configuration files, whether they be dashboard layouts, individual visualization parameters, or table calculation definitions. See YY for more details on the configuration of individual components.

# User feedback and iteration

# Limitations

# Discussion

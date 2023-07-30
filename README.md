# "Did Craigslist’s Erotic Services Reduce Female Homicide and Rape?" 
This Github Repository contains the scripts and data necessary to replicate all tables, figures, and appendicies from the forthcoming paper in the Journal of Human Resources, written by [Scott Cunningham](https://www.scunning.com/index.html), with [Gregory DeAngelo](http://gregoryjdeangelo.com) and [John Tripp](https://www.clemson.edu/business/about/profiles/JFTRIPP).

Media Coverage: [Huffington Post](https://www.huffpost.com/entry/craigslists-erotic-services-site-appears-to-have-reduced_b_59df8778e4b0cee7b9549e66) , [ThinkProgress](https://thinkprogress.org/craigslist-erotic-services-platform-3eab46092717/) , [Reply All](https://gimletmedia.com/shows/reply-all/o2ho97/119-no-more-safe-harbor#episode-player)

## Recreation Documents
Two scripts are needed to replicate all of the author's findings. Begin with **recreate_data_cleaning.do** to create "cleaned" data sets and follow along with the author's data decisions. Then run **recreate_main_tables.do** to recreate each figure and table from the main paper as well as the appendiez. Note: **recreate_main_tables.do** can only be run after these "cleaned" data sets are created.  

Neither script installs the STATA packages necessary to run all of the commands listed. The following commands are necessary:
```
sg30, csdid, reghdfe, drdid, missings, event_plot, estout, avar, ftools, github, eventstudyinteract, coefplott, moremata, twowayfeweights, carryforward, outreg2, stutex, cmogram, ddtiming, _gwtmean, fect
``` 

More information about fect can be found [here](https://raw.githubusercontent.com/xuyiqing/fect_stata/master/).

The latest versions of these commands can be obtained by running the following code in STATA: 
```
ssc install (name_of_command), replace
```

Initialized the app with:
```bash
mix phx.new stowly --no-html --no-dashboard --no-mailer
```

For the sake of this test, started claude with:
```bash
claude --dangerously-skip-permissions
```

Then ran `/init` to create the CLAUDE.md

We are in a freshly generated phoenix project called "Stowly". It is to become an Inventory Management System. It's intended to be run at home in a private network, so no authentication is necessary. Its purpose is to provide a very easy way for the user to categorize and store all items of a large collection of something. Think for example when having an electronics hobby, you'll have a lot of different parts and components that need to be stored in assortment boxes and must then be easy to find. It would be nice if the boxes, trays, drawers etc could be labelled, perhaps with a barcode or qr-code. The application must have a responsive design so that it may easily be used on laptop and on a phone. It would be very useful if the camera of phone or laptop may be used so that some javascript may automatically recognize barcode or qrcodef. The data should be stored in a well-organized ecto database backend (by default using postgresql). All the items must be search'able, with easy search bar where it doesn't matter whether you search on category, tags or other fields like names or whatever the user chooses. The different fields under which things are stored, whether they are tags or categories must be user-define'able. It must be easy to add them. It would be nice if we can also design and print the labels directly from the application. I have for example a Brother P-touch E550W label printer, which does have WIFI (only the linux driver seems to be difficult) anyway, using this label printer should be a separate step for implementing. It would be nice if the application also has the capability to maintain multiple collections. So let's say i have this electronics hobby, then i can create a collection "Electronics". But let's say i also have a stamp collection, then that could become a separate collection in the system. When searching, by default the search happens within the currently activated collection. We should heavily make use of live-views, so in essence it'll become an SPA (Single Page Application). Besides using the camera for the barcodes and qr codes, one should also be able to use the camera to make one or more photos of the object that is stored and categorized. These photos will be stored on disk while the metadata is stored in the database. I would like to have the feature to make a backup of the contentents of the database with (or when chosen without) the other media (like photos, videos, etc). This will then become a .tgz file, which can then also be used to restore from. For every item we must also have the capability to store how many of it we have. Other meta data could be external urls, descriptions, vendors, price (and lots more, please think of all the possibilities). Note that the interface should not be cluttered, so not show thousands of fields, but maybe only add them when the user added them ? It would be nice if we can theme the site somewhat, so that the electronics collection has different looks than the stamp-collection (perhaps by colors and background image or so). The app should be written in idiomatic elixir, with proper docs everywhere and complete unit testing. Put comments whenever deemed necessary.


● User answered Claude's questions:                                                                                                                                                                                
  ⎿  · Should I implement the full system phase by phase (committing after each phase), or would you prefer I tackle just the first few phases now? → Phase by phase, all                                          
     · What default currency should items use for price tracking? → Allow multiple prices to be set on an item, and with that define the price in a configurable currency for that item and at a specific order    
      quantity at a configurable vendor/store. So you can simply set a single price with currency or with the extra mentioned fields if the user wants.  

Then put on my QA hat and fixed several things:

❯ when i click on "new Collection", nothing happens                                                                                                                                                                

❯ i have now created one collection, but when i now click on "collections" to get the list view, i see an "empty" collection, no name is in it, nothing, and the created electronics collection. If i click on     
   the empty "slab" i also go to the electronics collection.                                                                                                                                                       

❯ I'm adding storage locations, when i add a location that already exists it doesn't work (which is good), but i don't see any error on my screen (like a flash message or so)

❯ When i delete a storage location that has child storage locations, it deletes it without any warning. Not sure if that also happens if actual collection items are stored in the location ?                      

❯ if i update the parent location of a location, it doesn't get updated

❯ When adding a category or a category in settings, i can choose a color. I now have to type in the color, but could i also have a color picker when i click on it ? then when clicking the color it fills in      
  the rgb hex value ?

❯ in the color picker can you display a little ok or cancel button, so that after one presses ok, the text field is updated ? if cancel is pressed or one clicks outside of the color picker, the color is         
  reset to what it was ? let the default textual value be the hex value, but i like that if you click on it that it shows the rgb or hsv value in the color picker. Can you also add a bunch of default colors     
   , like 9 different base colors or so ?

❯ make it 10 colors instead of 9 

❯ i have added a cateogry "Resistors", then have edited that category and renamed it to "Caps".. If i now add a category by the name of "Resistors", i get the error that the category with that name already      
  exists    



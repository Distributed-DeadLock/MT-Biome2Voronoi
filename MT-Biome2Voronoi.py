# import generativepy - Graphing Library
from generativepy.drawing import make_image, setup
from generativepy.geometry import Circle, Polygon, Rectangle, Transform
from generativepy.geometry import Text as gpText
from generativepy.color import Color
# import scipy Library with Voronoi-support
from scipy.spatial import Voronoi
# import random
import random
# import math
import math
# import the GUI Library
from tkinter import *
from tkinter import ttk
# import shopen for cross plattform shell-open
import pathlib, shopen


# Parse Lua/JSON Code into CSV
def ParseCodeFunc():
    toparse = code_text.get("1.0", END)
    # Loosening the text. make sure there is a space around everything important.
    toparse =  toparse.replace(":", "=")
    toparse =  toparse.replace("=", " = ")
    toparse =  toparse.replace(",", " ")
    toparse =  toparse.replace(";", " ")
    toparse =  toparse.replace("\"", " ")
    toparse =  toparse.replace("\'", " ")
    toparse =  toparse.replace("}", " ")
    toparse =  toparse.replace("{", " ")
    toparse =  toparse.replace("]", " ")
    toparse =  toparse.replace("[", " ")
    toparse =  toparse.replace(")", " ")
    toparse =  toparse.replace("(", " ")
    toparse =  toparse.replace("  ", " ")
    toparse =  toparse.replace("  ", " ")
    toparse =  toparse.replace("  ", " ")
    toparse =  toparse.replace("  ", " ")
    
    # Parse the list of tokens. looking for name,heat_point,humidity_point,y_min,y_max
    parselist = toparse.split()
    biomlist = list()
    for idx, item in enumerate(parselist):
        if (item == "name"):
            biomlist.insert(0, dict(name="",heat_point="",humidity_point="",y_min="",y_max=""))
            biomlist[0]["name"] = parselist[idx + 2]
        if (item == "heat_point"):
            biomlist[0]["heat_point"] = parselist[idx + 2]
        if (item == "humidity_point"):
            biomlist[0]["humidity_point"] = parselist[idx + 2]
        if (item == "y_min"):
            biomlist[0]["y_min"] = parselist[idx + 2]
        if (item == "y_max"):
            biomlist[0]["y_max"] = parselist[idx + 2]
    
    # Create CSV-List of Bioms
    new_csv = str()
    for biomdict in biomlist:
        new_csv = new_csv + biomdict["name"] + "," + biomdict["heat_point"] + "," + biomdict["humidity_point"] + "," + biomdict["y_min"] + "," + biomdict["y_max"] + "\n"
    list_text.insert("1.0", new_csv)
# 

# Select from CSV at Level
def SelectLevelCSV(csv,level):
    PLines = csv.splitlines()
    selcsv = ""
    for idx, item in enumerate(PLines):
        PFields = list()
        PFields = item.split(",")
        if PFields[3] and (int(PFields[3]) > level):
            continue
        if PFields[4] and (int(PFields[4]) < level):
            continue
        selcsv = selcsv + "\n" + item
    selcsv = selcsv.strip(" \n")
    return selcsv
#

# Parse CSV into Lists
def ParseCSV(csv):
    Points = list()
    Pointdict = dict()
    PLines = csv.splitlines()
    for idx, item in enumerate(PLines):
        PFields = list()
        PFields = item.split(",")
        currPointName = PFields[1] + ":" + PFields[2]
        if currPointName in Pointdict:
            Pointdict[currPointName].append(PFields[0])
        else:
            Pointdict.update({currPointName: [PFields[0]]})
            Points.append([PFields[1],PFields[2]])    
    return Points, Pointdict
#

# Draw the Voronoi Diagram

def drawVoronoi(ctx, pixel_width, pixel_height, frame_no, frame_count):
    setup(ctx, pixel_width, pixel_height, background=Color(1))
    SIZE = 2100
    vdpoints = list()
    for point in Points:
        vdpoints.append([(int(point[0])*20)+50,(int(point[1])*20)+50])
    # add 4 "border"-points to avoid open polygons
    vdpoints.append([-SIZE*3, -SIZE*3])
    vdpoints.append([-SIZE*3, SIZE*4])
    vdpoints.append([SIZE*4, -SIZE*3])
    vdpoints.append([SIZE*4, SIZE*4])

    # make voronoi-polygons
    voronoi = Voronoi(vdpoints)
    voronoi_vertices = voronoi.vertices

    for region in voronoi.regions:
       if -1 not in region:
           polygon = [voronoi_vertices[p] for p in region]
           Polygon(ctx).of_points(polygon).fill(Color(random.random()*0.9,random.random()*0.9,random.random()*0.9)).stroke(line_width=2)
    
    # make a border
    Rectangle(ctx).of_corner_size((0, 0), 50, 2100).fill(Color("black"))
    Rectangle(ctx).of_corner_size((0, 0), 2100, 50).fill(Color("black"))
    Rectangle(ctx).of_corner_size((2050, 0), 50, 2100).fill(Color("black"))
    Rectangle(ctx).of_corner_size((0, 2050), 2100, 50).fill(Color("black"))

    # make biome markers
    for point in Points:
        npoint = [(int(point[0])*20)+50,(int(point[1])*20)+50]
        dpoint = [(int(point[0])*20)+60,(int(point[1])*20)+60]
        pointpos = str(point[0]) + ":" + str(point[1])
        Circle(ctx).of_center_radius(npoint, 5).fill(Color("black"))
        gpText(ctx).of(pointpos, dpoint).size(20).font("Arial").fill(Color("white"))
        pointname = point[0] + ":" + point[1]
        for pn in Pointdict[pointname]:
            dpoint = [int(dpoint[0]),(int(dpoint[1])+22)]
            gpText(ctx).of(pn, dpoint).size(22).font("Arial").fill(Color("white"))
            
    # add Labeling
    gpText(ctx).of("---   HeatPoint   +++", [1050, 2090]).size(30).font("Arial").align_center().fill(Color("white"))
    with Transform(ctx).rotate(math.pi/-2, (1050, 1050)):
        gpText(ctx).of("+++   HumidityPoint   ---", [1050, 2090]).size(30).font("Arial").align_center().fill(Color("white"))


# Make Voronoi All Func
def MakeVoronoiAll():
    toparse = list_text.get("1.0", END)
    toparse = toparse.strip(" \n")
    global Points, Pointdict
    Points, Pointdict = ParseCSV(toparse)
    filename = filename_string.get() + ".png"
    make_image(filename, drawVoronoi, 2100, 2100)
    shopen.open(filename)
#    

# Make Voronoi at Level Func
def MakeVoronoiAtLevel():
    toparse = list_text.get("1.0", END)
    toparse = toparse.strip(" \n")
    atlevel = int(heightlevel_string.get())
    selected = SelectLevelCSV(toparse,atlevel)
    selected = selected.strip(" \n")
    global Points, Pointdict
    Points, Pointdict = ParseCSV(selected)
    filename = filename_string.get() + ".png"
    make_image(filename, drawVoronoi, 2100, 2100)
    shopen.open(filename)
#

# Create Main(root)-GUI
root = Tk()
root.title("MT: Biome to Voronoi Parser")
root.configure(background="#0f0f0f")
root.minsize(780, 600)  # width, height
root.geometry("780x600")  # width x height + x + y
 
# Create Frame widget Left
left_frame = Frame(root, width=380, height=460)
left_frame.grid(row=0, column=0, padx=10, pady=1, sticky="nwe")
left_frame.configure(background="#1f1f1f")
# In Left Frame
Label(left_frame, text="Lua/JSON to parse here:" ,background="#1f1f1f",foreground="#f0f0f0").grid(row=0, column=0, padx=5, pady=5)
# Textfield and subframe
codeinput = Frame(left_frame, width=370, height=440)
codeinput.grid(row=1, column=0, padx=0, pady=0)
code_text = Text(codeinput, width = 45, height = 28, wrap = "none")
code_text.grid(row=0, column=0, padx=0, pady=0, sticky="nwes")
# 

# Create Frame widget Right
right_frame = Frame(root, width=380, height=460)
right_frame.grid(row=0, column=1, padx=10, pady=1, sticky="nwe")
right_frame.configure(background="#1f1f1f")
# In Right Frame
Label(right_frame, text="Bioms (CSV): Name,Heat_Point,Humidity_Point,Y_Min,Y_Max" ,background="#1f1f1f",foreground="#f0f0f0").grid(row=0, column=0, padx=5, pady=5)
parsedlist = Frame(right_frame, width=370, height=440)
parsedlist.grid(row=1, column=0, padx=0, pady=0)
list_text = Text(parsedlist, width = 45, height = 28, wrap = "none")
list_text.grid(row=0, column=0, padx=0, pady=0, sticky="nwes")
# 

# Create Frame widget Bottom-Left
bottomleft_frame = Frame(root, width=380, height=100)
bottomleft_frame.grid(row=1, column=0, padx=10, pady=1, sticky="nwes")
bottomleft_frame.configure(background="#1f1f1f")
# In Bottom-Left Frame
# parse button
parse_code = Button(bottomleft_frame, text="Parse Lua/JSON", command=ParseCodeFunc)
parse_code.grid(row=0, column=0, padx=5, pady=5,sticky="w")
# 

# Create Frame widget Bottom-Right
bottomright_frame = Frame(root, width=380, height=100)
bottomright_frame.grid(row=1, column=1, padx=10, pady=1, sticky="nwes")
bottomright_frame.configure(background="#1f1f1f")
# In Bottom-Right Frame
# Generate-All button
generate_all = Button(bottomright_frame, text="Generate Voronoi with All Biomes",command=MakeVoronoiAll)
generate_all.grid(row=0, column=0, padx=5, pady=5,sticky="w")
# Generate-AT-Level button
generate_atlevel = Button(bottomright_frame, text="Generate Voronoi at Height",command=MakeVoronoiAtLevel)
generate_atlevel.grid(row=1, column=0, padx=5, pady=5, sticky="w")
# Height-Level Input Field
heightlevel_string = StringVar()
heightlevel = Entry(bottomright_frame, bd=3, exportselection=0, textvariable=heightlevel_string)
heightlevel.grid(row=1, column=1, padx=5, pady=5, sticky="e")
heightlevel_string.set( "0" )
# File-Name Input Field
filename_string = StringVar()
Label(bottomright_frame, text="Image File-Name (no extension):" ,background="#1f1f1f",foreground="#f0f0f0").grid(row=2, column=0, padx=5, pady=5, sticky="w")
filename = Entry(bottomright_frame, bd=3, exportselection=0, textvariable=filename_string)
filename.grid(row=2, column=1, padx=5, pady=5, sticky="e")
filename_string.set( "Voronoi" )
# 


root.mainloop()



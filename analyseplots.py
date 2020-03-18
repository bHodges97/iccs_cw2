import glob
import numpy as np
import imageio



homesick = []
none = []

for image_path in glob.glob("images/*.png"):
    image = imageio.imread(image_path)[...,:-1]

    cutoff = 0.93
    image = image[:int(image.shape[0] * cutoff),...]



    test = image[:,:] - [241,106,21]
    test = test ** 2
    s = np.sum(test,axis=2)
    #z = np.zeros_like(s)
    #mask = np.isclose(s,z,atol=10)
    mask = s < 20

    w = np.argwhere(mask)
    argx = np.argmax(w[:,1])
    x = w[argx,1]
    y = w[argx,0]


    region = image[:,x-10:x+5]
    imageio.imwrite("test.png",region)

    ratio = (test.shape[0] - y) / test.shape[0]

    colours = [[157,110,72],[237,237,49],[215,50,41],[167,27,106],[141,141,141],[241,106,21],[89,176,60],[44,209,59]]
    lang = 0
    for i in colours:
        if np.any(np.all(region[:,:] == i,axis=2)):
            lang+=1

    name = image_path.split("/")[-1]
    m,c,i = name.split("_")
    i = i.split(".")[0]
    lang = str(lang)
    y = str(y)
    ratio = str(ratio)
    if m == "none":
        none.append((c,i,lang,y,ratio))
    else:
        homesick.append((c,i,lang,y,ratio))

homesick = sorted(homesick,key=lambda x: float("0."+x[0]))
none = sorted(none,key=lambda x:float("0."+x[0]))
for i in homesick:
    print(" ".join(i))
print("none")
for i in none:
    print(" ".join(i))



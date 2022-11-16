# pfUI-RainbowHealthBar

This is an addon for World of Warcraft which is dependent on [pfUI](https://github.com/shagu/pfUI)(*you'd better download the latest version*),it's mainly works on the `UnitFrames` like the gif below shows:

![](https://raw.githubusercontent.com/WanLiQiaoXi/Assets/main/WowAddons/pfUI-RainbowHealthBar/124.gif?token=GHSAT0AAAAAAB2YLKIT3SM7EYKFAMMRKK6YY3U3CMQ)

## 3D Portrait enhance

You can also make a great behavior of 3D portrait by some feasible config.

![](https://raw.githubusercontent.com/WanLiQiaoXi/Assets/main/WowAddons/pfUI-RainbowHealthBar/129.gif?token=GHSAT0AAAAAAB2YLKISPE2Q72BRVMZVMEBEY3U4K6Q)

**Notice:** *Although i've done my best, that's even some bugs.*

### You should through 3 solutions behind while you find the portrait gotta  wrong behavior

* `Alt`+`z` to show/hide and refresh the UI
* `/run ReloadUI()` use the macro
* `/afk` this macro will load the pfUI afk module that has the same behavior as `Alt`+`z`

### Config steps

1. enable addon and reload UI

   ![](https://raw.githubusercontent.com/WanLiQiaoXi/Assets/main/WowAddons/pfUI-RainbowHealthBar/p3d_step_1.png?token=GHSAT0AAAAAAB2YLKISBS4CB7J6ZVNECUNYY3U5R7Q)

2. enable usable unitframe

3. now you need to add a model template to game's cache storage so that will auto display next time

   ![](https://raw.githubusercontent.com/WanLiQiaoXi/Assets/main/WowAddons/pfUI-RainbowHealthBar/p3d_step_2.png?token=GHSAT0AAAAAAB2YLKISQSSRKH6NDQETTVX4Y3U5TBA)

**Notice:** *You must know that different creature has the different 3d model size especially the height!*

![](https://raw.githubusercontent.com/WanLiQiaoXi/Assets/main/WowAddons/pfUI-RainbowHealthBar/World_of_Warcraft_-_Player_Model_Height_Chart.png?token=GHSAT0AAAAAAB2YLKISZK4LLQF3H2WZYMVEY3U5TXA)

**The different height makes the same configuration get a wrong performance. **

![](https://raw.githubusercontent.com/WanLiQiaoXi/Assets/main/WowAddons/pfUI-RainbowHealthBar/wrong_height_performance.png?token=GHSAT0AAAAAAB2YLKISL57KDKGKZQMHHOZOY3U533A)

`So that you must add a template for every single creature or model type!!!`


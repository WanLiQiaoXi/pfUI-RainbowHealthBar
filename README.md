# pfUI-RainbowHealthBar

This is an addon for World of Warcraft which is dependent on [pfUI](https://github.com/shagu/pfUI)(*you'd better download the latest version*),it's mainly works on the `UnitFrames` like the gif below shows:

![](https://raw.githubusercontent.com/WanLiQiaoXi/Assets/main/WowAddons/pfUI-RainbowHealthBar/124.gif)

**The gradient rainbow bar is a clone from RUF which is build at v1.13.x not compatible with vanilla WOW.**

## 3D Portrait enhance

You can also make a great behavior of 3D portrait by some feasible config.

![](https://raw.githubusercontent.com/WanLiQiaoXi/Assets/main/WowAddons/pfUI-RainbowHealthBar/129.gif)

**Notice:** *Although i've done my best, that's even some bugs.*

### More interesting things

To have fun in an old game, I think it's more appealing than the game content itself. After all, the old game world has been played thousands of times, but it's worth looking into something new that is unknown to the player themselves.

So I set out to implement the animation function of the 3D portrait model, it looks like the picture below shows:

![](https://raw.githubusercontent.com/WanLiQiaoXi/Assets/main/WowAddons/pfUI-RainbowHealthBar/p3d_giant_dragon_2.gif)

For a huge model like a dragon, we can also achieve the style shown in the picture above through a certain configuration. You may be more concerned with the specific options of the configuration, and here I can give a personal template:

![](https://raw.githubusercontent.com/WanLiQiaoXi/Assets/main/WowAddons/pfUI-RainbowHealthBar/p3d_giant_dragon_conf.jpg)

**Here** is an example after changing the animation of 3D portraits: 

![](https://raw.githubusercontent.com/WanLiQiaoXi/Assets/main/WowAddons/pfUI-RainbowHealthBar/p3d_giant_dragon.gif)

### You should through 3 solutions behind while you find the portrait gotta  wrong behavior

* `Alt`+`z` to show/hide and refresh the UI
* `/run ReloadUI()` use the macro
* `/afk` this macro will load the pfUI afk module that has the same behavior as `Alt`+`z`

### Config steps

1. enable addon and reload UI

   ![](https://raw.githubusercontent.com/WanLiQiaoXi/Assets/main/WowAddons/pfUI-RainbowHealthBar/p3d_step_1.png)

2. enable usable unitframe

3. now you need to add a model template to game's cache storage so that will auto display next time

   ![](https://raw.githubusercontent.com/WanLiQiaoXi/Assets/main/WowAddons/pfUI-RainbowHealthBar/p3d_step_2.png)

**Notice:** *You must know that different creature has the different 3d model size especially the height!*

![](https://raw.githubusercontent.com/WanLiQiaoXi/Assets/main/WowAddons/pfUI-RainbowHealthBar/World_of_Warcraft_-_Player_Model_Height_Chart.png)

**The different height makes the same configuration get a wrong performance.**

![](https://raw.githubusercontent.com/WanLiQiaoXi/Assets/main/WowAddons/pfUI-RainbowHealthBar/wrong_height_performance.png)

`So that you must add a template for every single creature or model type!!!`

## More health bar textures

I copy some StatusBar textures from RUF and TukUI, you can change the health/power bar texture from pfUI config panel.

![](https://raw.githubusercontent.com/WanLiQiaoXi/Assets/main/WowAddons/pfUI-RainbowHealthBar/130.gif)

All textures:

![](https://raw.githubusercontent.com/WanLiQiaoXi/Assets/main/WowAddons/pfUI-RainbowHealthBar/132.gif)

# Changes

### 2023-09-28

* fix:  make the slider smoother with continuous clicks

* feature: add combobox widget for pfUI config

  ![](https://raw.githubusercontent.com/WanLiQiaoXi/Assets/main/WowAddons/pfUI-RainbowHealthBar/p3d_combobox_0.gif)

* feature: add support for 3d portrait's animations

  ![](https://raw.githubusercontent.com/WanLiQiaoXi/Assets/main/WowAddons/pfUI-RainbowHealthBar/p3d_seq_0.gif)

* refactor: add the alpha value of 3d portrait model as the configuration cache data to ensure that each model has a separate alpha value

### 2022-11-18

* add a gray filter layer to all targets' unitframe and you can easily distinguish your mobs from the other players

  **Target**
  
  ![](https://raw.githubusercontent.com/WanLiQiaoXi/Assets/main/WowAddons/pfUI-RainbowHealthBar/target_tapped.png)
  
  **TargetTarget**
  
  ![](https://raw.githubusercontent.com/WanLiQiaoXi/Assets/main/WowAddons/pfUI-RainbowHealthBar/targettarget_tapped.png)
  
* now you can set the backdrop texture fix to the statusbar it belongs to and change the textures' blend mode
  
  **before setting:**
  
  ![](https://raw.githubusercontent.com/WanLiQiaoXi/Assets/main/WowAddons/pfUI-RainbowHealthBar/135.gif)
  
  **after setting:**
  
  ![](https://raw.githubusercontent.com/WanLiQiaoXi/Assets/main/WowAddons/pfUI-RainbowHealthBar/134.gif)
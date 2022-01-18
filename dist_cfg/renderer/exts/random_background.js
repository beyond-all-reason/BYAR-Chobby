'use strict';

var images = [  './images/backgrounds/1.png',
                './images/backgrounds/2.png',
                './images/backgrounds/3.png',
                './images/backgrounds/4.png',
                './images/backgrounds/5.png',
                './images/backgrounds/6.png',
                './images/backgrounds/7.png',
            ];        

var imageName = images[Math.floor(Math.random() * images.length)];
//console.log("ImageName:" +imageName);          
document.getElementById("main-content").style.backgroundImage = "url("+imageName+")"; 
'use strict';

var images = [  './images/backgrounds/1.png',
                './images/backgrounds/2.png',
                './images/backgrounds/3.png',
                './images/backgrounds/4.png',
                './images/backgrounds/5.png',
                './images/backgrounds/6.png',
                './images/backgrounds/7.png',
                './images/backgrounds/8.jpg',
                './images/backgrounds/9.png',
                './images/backgrounds/10.jpg',
                './images/backgrounds/11.jpg',
                './images/backgrounds/12.png',
                './images/backgrounds/13.png',
                './images/backgrounds/14.png',
                './images/backgrounds/15.png',
                './images/backgrounds/16.png',
            ];        

var imageName = images[Math.floor(Math.random() * images.length)];
//console.log("ImageName:" +imageName);          
document.getElementById("main-content").style.backgroundImage = "url("+imageName+")"; 
# Owncast

Short story long. My daughter's gym needed to live stream her competition. I ended up using OBS and YouTube to some success. However since YouTube doesn't allow fair use for music they kept "copyright claim" blocking the videos. One stream they even stopped the stream in the middle of it. The workaround is to use stream using 2 hour blocks. This is not ideal when you have people watching from all over the world. The solution is [Owncast](https://owncast.online/). Host my own service!

## My Setup

Fairly simple:

* Stand up VM
  * Any OS. Deploy Docker
  * Check out my script [owncast.sh](https://github.com/clemenko/owncast/blob/main/owncast.sh)
* Deploy Owncast
  * Deploy along side [Traefik](https://traefik.io). Traefik will use Let's Encrypt for certs.
  * Here is a docker-compose that I use [docker-compose.yml](https://github.com/clemenko/owncast/blob/main/docker-compose.yml).
* Configure Owncast with S3
  * Orginially I set everything up with Digital Ocean Spaces. But the CDN they provide wouldn't work with Safari browsers. So I switched to [Wasabi](https://wasabi.com/). Here are the owncast [docs for Wasabi](https://owncast.online/docs/storage/wasabi/).
* Configure OBS
  * There are a LOT of settings. Here are the highlights. Twitch has a [page for the details](https://stream.twitch.tv/encoding/).
    * MAX resolution 1080p at 60fps
    * MAX bitrate 6000kps
    * Keyframe internval 2
    * Audio Sample rate 44.1kHz
* Pro TIPS
  * NO WIFI. Which every computer you are using to stream from. IT MUST USE ethernet. We have streamed about a dozen times and all but the last one was wifi. Wifi has always dropped packets. Ethernet never dropped a single packet. NO MOAR WIFI!
* Profit

## Lessons Learned

No wifi is the pro tip for the month. The difference was night and day. 
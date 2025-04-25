package main

rotr :: proc(x: u32, y: u32) -> u32 {
  return (x >> y) | (x << (32 - y))
}

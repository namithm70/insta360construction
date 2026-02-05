package com.arashivision.sdk.lib

import java.io.File

fun main() {
    val file = File("G:\\aaa.txt")
    file.readLines().forEach {
        val split = it.split("=")
        if(split[0].contains("null")){
            println(it)
        }else{
            println("${split[1]}?.let{ ${split[0]} = it }")
        }
    }
}
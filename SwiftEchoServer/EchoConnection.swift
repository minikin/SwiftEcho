//
//  EchoConnection.swift
//  SwiftEcho
//
//  Created by Sasha Minikin on 1/17/17.
//  Copyright © 2017 Sasha Prokhorenko. All rights reserved.
//

import Foundation

let echoConnectionDidCloseNotification = "EchoConnectionDidCloseNotification"

class EchoConnection: NSObject {
  
  var inputStream: InputStream
  var outputStream: OutputStream
  
  init(inputStream: InputStream, outputStream: OutputStream) {
    self.inputStream = inputStream
    self.outputStream = outputStream
  }
  
  func open() -> Bool {
    inputStream.delegate = self
    outputStream.delegate = self
    inputStream.schedule(in: RunLoop.current, forMode:RunLoopMode.defaultRunLoopMode)
    outputStream.schedule(in: RunLoop.current, forMode:RunLoopMode.defaultRunLoopMode)
    inputStream.open()
    outputStream.open()
    
    return true
  }
  
  func close(){
    inputStream.delegate = nil
    outputStream.delegate = nil
    inputStream.close()
    outputStream.close()
    inputStream.remove(from: RunLoop.current, forMode:RunLoopMode.defaultRunLoopMode)
    outputStream.remove(from: RunLoop.current, forMode:RunLoopMode.defaultRunLoopMode)
  
    NotificationCenter.default.post(name: NSNotification.Name(rawValue: echoConnectionDidCloseNotification), object: self)
  }

}

extension EchoConnection: StreamDelegate {
  
  func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
    assert(aStream == inputStream || aStream == outputStream)
    
    switch eventCode {
    case Stream.Event.hasBytesAvailable:
      let buffer = [UInt8].init(repeating: UInt8(), count: 2048)
      let actuallyRead : Int = inputStream.read(UnsafeMutablePointer<UInt8>(mutating: buffer), maxLength:Int(buffer.count))
      if actuallyRead > 0 {
        let actuallyWritten: Int = outputStream.write(buffer, maxLength: Int(buffer.count))
        if actuallyWritten != actuallyRead {
          // -write:maxLength: may return -1 to indicate an error or a non-negative
          // value less than maxLength to indicate a 'short write'.  In the case of an
          // error we just shut down the connection.  The short write case is more
          // interesting.  A short write means that the client has sent us data to echo but
          // isn't reading the data that we send back to it, thus causing its socket receive
          // buffer to fill up, thus causing our socket send buffer to fill up.  Again, our
          // response to this situation is that we simply drop the connection
          close()
        } else {
          print("Echoed bytes")
        }
      } else {
        // A non-positive value from -read:maxLength: indicates either end of file (0) or
        // an error (-1).  In either case we just wait for the corresponding stream event
        // to come through.
      }
    case Stream.Event.errorOccurred:
      close()
    case Stream.Event.hasSpaceAvailable:
      print("hasSpaceAvailable")
    case Stream.Event.openCompleted:
      print("openCompleted")
    default:
      break
    }
  }
  
}

//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
// swift-tools-version:4.0
//
// swift-tools-version:4.0
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
import NIO
import NIOTransportServices
import NIOHTTP1
import Network

final class HTTP1ServerHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let part = self.unwrapInboundIn(data)

        guard case .head = part else {
            return
        }

        let responseHeaders = HTTPHeaders([("server", "nio-transport-services"), ("content-length", "0")])
        let responseHead = HTTPResponseHead(version: .init(major: 1, minor: 1), status: .ok, headers: responseHeaders)
        ctx.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
        ctx.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
    }
}

let group = NIOTSEventLoopGroup()
let channel = try! NIOTSListenerBootstrap(group: group)
    .childChannelInitializer { channel in
        channel.pipeline.configureHTTPServerPipeline(withPipeliningAssistance: true, withErrorHandling: true).then {
            channel.pipeline.add(handler: HTTP1ServerHandler())
        }
    }.bind(host: "127.0.0.1", port: 8888).wait()

print("Server listening on \(channel.localAddress!)")

// Wait for the request to complete
try! channel.closeFuture.wait()
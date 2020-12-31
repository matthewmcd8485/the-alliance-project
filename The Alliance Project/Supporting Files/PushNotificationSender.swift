//
//  PushNotificationSender.swift
//  The Alliance Project
//
//  Created by Matthew McDonnell on 11/24/20.
//  Copyright © 2020 Matthew McDonnell. All rights reserved.
//

import UIKit

class PushNotificationSender {
    func sendPushNotification(to token: String, title: String, body: String) {
        let urlString = "https://fcm.googleapis.com/fcm/send"
        let url = NSURL(string: urlString)!
        let paramString: [String : Any] = ["to" : token,
                                           "notification" : ["title" : title, "subtitle" : "New Message", "body" : body, "badge" : 1, "sound" : "default"],
                                           "data" : ["user" : "test_id"]
        ]

        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject:paramString, options: [.prettyPrinted])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=AAAAMdKm6lo:APA91bEjhuHiuzN2fmCDZtpQ19-hc-Q-kGgTZFhrJnntFcMRYVnIv7fhhzA_NcuAosHqlNsesC1beznkvcixN8bLIZr2Zv9NBTi8JHPDaI5XckcihfBgmsF66w451UlGGq4ICIzEQwC0", forHTTPHeaderField: "Authorization")

        let task =  URLSession.shared.dataTask(with: request as URLRequest)  { (data, response, error) in
            do {
                if let jsonData = data {
                    if let jsonDataDict  = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
                        NSLog("Received data:\n\(jsonDataDict))")
                    }
                }
            } catch let err as NSError {
                print(err.debugDescription)
            }
        }
        task.resume()
    }
}

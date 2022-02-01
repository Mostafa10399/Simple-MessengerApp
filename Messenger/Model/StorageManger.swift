//
//  StorageManger.swift
//  Flash Chat iOS13
//
//  Created by Mostafa Mahmoud on 1/9/22.
//  Copyright © 2022 Angela Yu. All rights reserved.
//

import Foundation
import FirebaseStorage
import SwiftUI


///allows you fetch,get and upload files to firebase storage
class StorageManger
{
    private init (){}
    static let shared = StorageManger()
    private let storage = Storage.storage().reference()
    typealias UploadPictureCompletion = (Result<String,Error>)->Void
    //MARK: - Upload Picture
    
    /// uploading a picture to firebase storage
    public func uploadPictureCompletion(with data:Data,fileName:String, completion: @escaping UploadPictureCompletion)
    {
        storage.child("images/\(fileName)").putData(data, metadata: nil) {[weak self] metaData, error in
            guard let strongSelf = self else
            {
                return
            }
            if let e = error
            {
                print(e)
                print ("failed to upload data to firebase for picture")
                completion(.failure(StorageError.failedToUpload))
            }
            else
            {
                let refrence = strongSelf.storage.child("images/\(fileName)").downloadURL { url, error in
                    if let e = error
                    {
                        print(e)
                        completion(.failure(StorageError.failedToDownloadURL))
                    }
                    else
                    {
                        if let urlLink = url
                        {
                            let urlString = urlLink.absoluteString
                            print("download url returned:\(urlString) ")
                            completion(.success(urlString))
                            
                        }
                    }
                    
                    
                }
            }
        }
        
        
    }
    typealias ResultCompletion = (Result<URL,Error>)->Void
    //MARK: - Download Url
    
    /// download a picture from a firebase storage
    func downloadUrl(with path:String,Completion: @escaping  ResultCompletion){
        let refrence = storage.child(path)
        refrence.downloadURL { url, error in
            if let e = error
            {
                print(e.localizedDescription)
                Completion(.failure(StorageError.failedToDownloadURL))
            }
            
            else
            {
                if let url = url
                {
                    Completion(.success(url))
                }
            }
            
        }
    }
        
        enum StorageError:Error
        {
            case failedToUpload
            case failedToDownloadURL
        }
    
    //MARK: - Upload image that will be sent in the conversation message
    public func uploadMessagePhoto(with data:Data,fileName:String, completion: @escaping UploadPictureCompletion)
    {
        storage.child("MessageImages/\(fileName)").putData(data, metadata: nil) {[weak self] metaData, error in
            guard let strongSelf = self else
            {
                return
            }
            if let e = error
            {
                print(e)
                print ("failed to upload data to firebase for picture")
                completion(.failure(StorageError.failedToUpload))
            }
            else
            {
                let refrence = strongSelf.storage.child("MessageImages/\(fileName)").downloadURL { url, error in
                    if let e = error
                    {
                        print(e)
                        completion(.failure(StorageError.failedToDownloadURL))
                    }
                    else
                    {
                        if let urlLink = url
                        {
                            let urlString = urlLink.absoluteString
                            print("download url returned:\(urlString) ")
                            completion(.success(urlString))
                            
                        }
                    }
                    
                    
                }
            }
        }
        
        
    }
    
    //MARK: - uploading video
    
    public func uploadMessageVideo(with fileURL:URL,fileName:String, completion: @escaping UploadPictureCompletion)
    {
        storage.child("MessageVideos/\(fileName)").putFile(from:fileURL, metadata: nil) {[weak self] metaData, error in
            guard let strongSelf = self else {
                return
            }
            if let e = error
            {
                print(e)
                print ("failed to upload Video to firebase ")
                completion(.failure(StorageError.failedToUpload))
            }
            else
            {
                let refrence = strongSelf.storage.child("MessageVideos/\(fileName)").downloadURL { url, error in
                    if let e = error
                    {
                        print(e)
                        completion(.failure(StorageError.failedToDownloadURL))
                    }
                    else
                    {
                        if let urlLink = url
                        {
                            let urlString = urlLink.absoluteString
                            print("download url returned:\(urlString) ")
                            completion(.success(urlString))
                            
                        }
                    }
                    
                    
                }
            }
        }
        
        
    }
    
    }

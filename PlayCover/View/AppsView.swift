//
//  AppsLibraryView.swift
//  PlayCover
//

import Foundation

import SwiftUI
import Cocoa

struct AppsView : View {
    @Binding public var bottomPadding: CGFloat
    
    @EnvironmentObject var vm : AppsVM
    
    @State private var gridLayout = [GridItem(.adaptive(minimum: 150, maximum: 150), spacing: 10)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center){
                Spacer()
                SearchView().padding(.leading, 36)
                Image("Happy").resizable().frame(width: 64, height: 64).padding(.bottom, 0).padding(.trailing, 16)
            }.padding(.top, 0)
            Divider().padding(.top, 0).padding(.leading, 36).padding(.trailing, 36)
            ScrollView() {
                LazyVGrid(columns: gridLayout, spacing: 10) {
                    ForEach(vm.apps, id:\.id) { app in
                        if app.type == BaseApp.AppType.add {
                            AppAddView().environmentObject(InstallVM.shared)
                        } else if app.type == .app{
                            PlayAppView(app: app as! PlayApp)
                        } else if app.type == .store {
                            StoreAppView(app: app as! StoreApp)
                        }
                    }
                }
                .padding(.top, 16).padding(.bottom, bottomPadding + 16)
                .animation(.spring())
            }
        }
    }
}

struct AppAddView : View {
    
    @State var isHover : Bool = false
    @State var showWrongfileTypeAlert : Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var install : InstallVM
    
    func elementColor(_ dark : Bool) -> Color {
        return isHover ? Colr.controlSelect().opacity(0.3) : Color.black.opacity(0.0)
    }
    
    var body: some View {
        
        VStack(alignment: .center, spacing: 0) {
            Image(systemName: "plus.square")
                .font(.system(size: 38.0, weight: .thin))
                .frame(width: 64, height: 68).padding(.top).foregroundColor(
                    install.installing ? Color.gray : Colr.primary)
            Text("Add app").padding(.horizontal).frame(width: 150, height: 50).padding(.bottom).lineLimit(nil).foregroundColor( install.installing ? Color.gray : Colr.primary).minimumScaleFactor(0.8).multilineTextAlignment(.center)
        }.background(colorScheme == .dark ? elementColor(true) : elementColor(false))
            .cornerRadius(16.0)
            .frame(width: 150, height: 150).onHover(perform: { hovering in
                isHover = hovering
            }).alert(isPresented: $showWrongfileTypeAlert) {
                Alert(title: Text("Wrong file type"), message: Text("Choose an .ipa file"), dismissButton: .default(Text("OK")))
            }
            .onTapGesture {
                if install.installing{
                    isHover = false
                    Log.shared.error(PlayCoverError.waitInstallation)
                } else{
                    isHover = false
                    selectFile()
                }
                
            }.onDrop(of: ["public.url","public.file-url"], isTargeted: nil) { (items) -> Bool in
                if install.installing{
                    Log.shared.error(PlayCoverError.waitInstallation)
                    return false
                } else if let item = items.first {
                    if let identifier = item.registeredTypeIdentifiers.first {
                        if identifier == "public.url" || identifier == "public.file-url" {
                            item.loadItem(forTypeIdentifier: identifier, options: nil) { (urlData, error) in
                                DispatchQueue.main.async {
                                    if let urlData = urlData as? Data {
                                        let urll = NSURL(absoluteURLWithDataRepresentation: urlData, relativeTo: nil) as URL
                                        if urll.pathExtension == "ipa"{
                                            uif.ipaUrl = urll
                                            installApp()
                                        } else{
                                            showWrongfileTypeAlert = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                    return true
                } else {
                    return false
                }
            }
            .handlesExternalEvents(preferring: Set(arrayLiteral: "{path of URL?}"), allowing: Set(arrayLiteral: "*")) // // activate existing window if exists
            .onOpenURL{url in
                if url.pathExtension == "ipa"{
                    uif.ipaUrl = url
                    installApp()
                } else{
                    showWrongfileTypeAlert = true
                }
            }
    }
    
    private func installApp(){
        Installer.install(ipaUrl : uif.ipaUrl! , returnCompletion: { (app) in
            DispatchQueue.main.async {
                AppsVM.shared.fetchApps()
                NotifyService.shared.notify("App installed!", "Check it out in 'My Apps'")
            }
        })
    }
    
    private func selectFile() {
        NSOpenPanel.selectIPA { (result) in
            if case let .success(url) = result {
                uif.ipaUrl = url
                installApp()
            }
        }
    }
    
}

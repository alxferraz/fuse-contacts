using Uno;
using Uno.UX;
using Uno.Threading;
using Fuse;
using Fuse.Scripting;
using Fuse.Reactive;
using Bolav.ForeignHelpers;
using Uno.Permissions;
using Uno.Compiler.ExportTargetInterop;
using Fuse.Controls.Native.Android;

[ForeignInclude(Language.Java, "android.content.pm.PackageManager")]
[ForeignInclude(Language.Java, "android.support.v4.app.ActivityCompat")]
[ForeignInclude(Language.Java, "com.fuse.Activity")]

[extern(iOS) Require("Xcode.Framework", "AddressBook")]
[extern(iOS) Require("Source.Import","AddressBook/AddressBook.h")]

[UXGlobalModule]
public class Contacts : NativeModule {

	static readonly Contacts _instance;
	NativeEvent _resultEvent;

	public Contacts()
	{
		//if (_instance != null) return;
		_instance = this;
		Uno.UX.Resource.SetGlobalKey(_instance, "Contacts");
		 _resultEvent = new NativeEvent("onResult");
        AddMember(_resultEvent);
		AddMember(new NativeFunction("getAll", (NativeCallback)GetAll));
		AddMember(new NativeFunction("getPage", (NativeCallback)GetPage));
		AddMember(new NativeFunction("askContactPermission", (NativeCallback)AskContactPermission));
		AddMember(new NativeFunction("checkContactsPermissionIsGranted", (NativeCallback)CheckContactsPermissionIsGranted));
	}

	object GetAll (Context c, object[] args)
	{
		var a = new JSList(c);
		ContactsImpl.GetAllImpl(a);
		return a.GetScriptingArray();
	}

	object GetPage (Context c, object[] args)
	{
		var a = new JSList(c);
		ContactsImpl.GetPageImpl(a, Marshal.ToInt(args[0]), Marshal.ToInt(args[1]));
		return a.GetScriptingArray();
	}

	Future<string> Authorize (object[] args)
	{
		return ContactsImpl.AuthorizeImpl();
	}

	static Promise<string> _authorizePromise;

	public static Future<string> AuthorizeImpl()
	{
		//if (_authorizePromise == null)
		//{
			_authorizePromise = new Promise<string>();
			
		//}
		return _authorizePromise;
	}

	object AskContactPermission(Context c, object[] args)
    {
        if defined(Android)
        {
            if (!CheckContactsPermissionGranted()) {
            	var permissionPromise = Permissions.Request(Permissions.Android.READ_CONTACTS);
            	permissionPromise.Then(Execute, Reject);
            }
            else 
            {
            	_resultEvent.RaiseAsync(_resultEvent.ThreadWorker, "AuthorizationAuthorized");
            }
        }
        else if defined(iOS) {
        	
        	var status = GetAuthorizationStatusiOS();
			if (status == "AuthorizationNotDetermined") {
				RequestAuthorizationiniOS();
			}
			else if (status == "AuthorizationAuthorized") {
				_resultEvent.RaiseAsync(_resultEvent.ThreadWorker, "AuthorizationAuthorized");
			}
			else if (status == "AuthorizationDenied") {
				_resultEvent.RaiseAsync(_resultEvent.ThreadWorker, "AuthorizationDenied");
			}
        }     
        else 
        {
            _resultEvent.RaiseAsync(_resultEvent.ThreadWorker, "AuthorizationDenied");
        }
        return null;
    }

    object CheckContactsPermissionIsGranted(Context c, object[] args)
    {
        if defined(Android)
        {
            return CheckContactsPermissionGranted();
        }
        else if defined(iOS) {
        	var status = GetAuthorizationStatusiOS();
        	if (status == "AuthorizationAuthorized") {
				return true;
			}
			else  {
				return false;
			}
        }     
        else 
        {
            debug_log "Permission.uno::Permission required only on Android";
        }
        return null;
    }

    [Foreign(Language.Java)]
    extern(Android) bool CheckContactsPermissionGranted()
    @{
        return ActivityCompat.checkSelfPermission(Activity.getRootActivity(), android.Manifest.permission.READ_CONTACTS) ==
                PackageManager.PERMISSION_GRANTED ;
    @}

    extern(Android) void Execute(PlatformPermission grantedPermissions)
    {
         _resultEvent.RaiseAsync(_resultEvent.ThreadWorker, "AuthorizationAuthorized");
    }

    extern(Android) void Reject(Exception e)
    {
        _resultEvent.RaiseAsync(_resultEvent.ThreadWorker, "AuthorizationRejected");
    }

    void resultCb( string str )
    {
        _resultEvent.RaiseAsync(_resultEvent.ThreadWorker, str);
    }

    [Foreign(Language.ObjC)]
	extern(iOS) string GetAuthorizationStatusiOS()
	@{
		ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();

		if (status == kABAuthorizationStatusDenied) {
			return @"AuthorizationDenied";
		}
		else if (status == kABAuthorizationStatusRestricted) {
			return @"AuthorizationRestricted";
		}
		else if (status == kABAuthorizationStatusNotDetermined) {
			return @"AuthorizationNotDetermined";
		}
		else if (status == kABAuthorizationStatusAuthorized) {
			return @"AuthorizationAuthorized";
		}
		else {
			return @"Unknown";
		}
	@}

    [Foreign(Language.ObjC)]
	extern(iOS) void RequestAuthorizationiniOS() 
	@{
		CFErrorRef error = NULL;
		ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
		if (!addressBook) {
		    NSString* deviceModel = @"Error getting addressBook";
		    @{Contacts:Of(_this).resultCb(string):Call(@"Error getting addressBook")};
		    return;
		}

		ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
		    if (error) {
		        @{Contacts:Of(_this).resultCb(string):Call(@"Error getting access")};
		    }
		    if (granted) {
		    	@{Contacts:Of(_this).resultCb(string):Call(@"AuthorizationAuthorized")};
		    } else {
		    	@{Contacts:Of(_this).resultCb(string):Call(@"AuthorizationDenied")};
		    }
		    CFRelease(addressBook);
		});
	@}
	

}


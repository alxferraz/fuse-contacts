using Android;
using Uno;
using Uno.Collections;
using Fuse;
using Bolav.ForeignHelpers;
using Uno.Threading;

using Uno.Compiler.ExportTargetInterop;
using Uno.Permissions;

using Uno.Graphics;
using Uno.Platform;

using Fuse.Controls;
using Fuse.Triggers;
using Fuse.Resources;


[ForeignInclude(Language.Java,
                "android.provider.ContactsContract",
                "android.content.ContentResolver",
                "android.app.Activity",
                "android.content.Intent",
                "android.net.Uri",
                "android.database.Cursor",
                "android.util.Log",
                "org.json.JSONObject",
                "org.json.JSONArray",
                "java.util.List",
                "java.util.ArrayList",
                "java.util.Arrays",
                "com.wafflecopter.multicontactpicker.MultiContactPicker",
                "com.wafflecopter.multicontactpicker.ContactResult"
                )]
[Require("Gradle.Repository", "maven { url 'https://jitpack.io' }")]
[Require("Gradle.Repository", "maven { url 'https://maven.google.com' }")]
[Require("Gradle.Dependency.Compile", "com.github.alxferraz:MultiContactPicker:v1.9.1")]

public extern(Android) class ContactsImpl
{

	// http://stackoverflow.com/questions/12562151/android-get-all-contacts
  [Foreign(Language.Java)]
  public static void log(string text)
  @{
  Log.i("unolog",text);
  @}


  [Foreign(Language.Java)]
	public static void GetAllImpl(ForeignList ret)
	@{
		Activity a = com.fuse.Activity.getRootActivity();
		ContentResolver cr = a.getContentResolver();
		String selection =  ContactsContract.Contacts.IN_VISIBLE_GROUP + " = ?";
		String[] Args = { "1" };
		Cursor cur = cr.query(ContactsContract.Contacts.CONTENT_URI,
		        null, selection, Args, null);

		if (cur.getCount() > 0) {
		    while (cur.moveToNext()) {
		    	Object row = @{ForeignList:Of(ret).NewDictRow():Call()};

		    	String id = cur.getString(
		    	                cur.getColumnIndex(ContactsContract.Contacts._ID));

		    	@{ForeignDict:Of(row).SetKeyVal(string,string):Call("id", id)};
		    	@{ForeignDict:Of(row).SetKeyVal(string,string):Call("name",
		    		cur.getString(cur.getColumnIndex(ContactsContract.Contacts.DISPLAY_NAME)) )};

		    	// read the phone numbers at the current cursor
		        if (Integer.parseInt(cur.getString(cur.getColumnIndex(
		                    ContactsContract.Contacts.HAS_PHONE_NUMBER))) > 0) {
		            Cursor pCur = cr.query(
		                    ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
		                    null,
		                    ContactsContract.CommonDataKinds.Phone.CONTACT_ID +" = ?",
		                    new String[]{id}, null);

		            Object phoneList = @{ForeignDict:Of(row).AddListForKey(string):Call("phone")};
		            while (pCur.moveToNext()) {
		            	Object phoneRow = @{ForeignList:Of(phoneList).NewDictRow():Call()};
		            	@{ForeignDict:Of(phoneRow).SetKeyVal(string,string):Call("phone",
		            		pCur.getString(pCur.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER))
		            		)};

		            }
		            pCur.close();
		        }

		    	// read the e-mail addresses at the current cursor
				Cursor emailCur = cr.query(
			 				ContactsContract.CommonDataKinds.Email.CONTENT_URI,
			 				null,
			 				ContactsContract.CommonDataKinds.Email.CONTACT_ID + " = ?",
			 				new String[]{id}, null);
				Object emailList = @{ForeignDict:Of(row).AddListForKey(string):Call("email")};
		 		while (emailCur.moveToNext()) {
	            	Object emailRow = @{ForeignList:Of(emailList).NewDictRow():Call()};
	            	@{ForeignDict:Of(emailRow).SetKeyVal(string,string):Call("email",
	            		emailCur.getString(emailCur.getColumnIndex(ContactsContract.CommonDataKinds.Email.DATA))
	            		)};
		 		}
		 		emailCur.close();
		    }
		}
		cur.close();
	@}


  [Foreign(Language.Java)]
	public static void GetPageImpl(ForeignList ret, int numRows, int curPage)
	@{
		Activity a = com.fuse.Activity.getRootActivity();
		ContentResolver cr = a.getContentResolver();
		String selection =  ContactsContract.Contacts.IN_VISIBLE_GROUP + " = ?";
		String[] Args = { "1" };
		String limiter = "display_name COLLATE LOCALIZED LIMIT " + numRows + " OFFSET " + (numRows * curPage);
		Cursor cur = cr.query(ContactsContract.Contacts.CONTENT_URI,
		        null, selection, Args, limiter);

		// DatabaseUtils.dumpCursor(cur);

		if (cur != null) {
			if (cur.getCount() > 0) {
			    while (cur.moveToNext()) {
			    	Object row = @{ForeignList:Of(ret).NewDictRow():Call()};

			    	String id = cur.getString(cur.getColumnIndex(ContactsContract.Contacts._ID));
			    	// @{ForeignDict:Of(row).SetKeyVal(string,string):Call("id", id)};
			    	@{ForeignDict:Of(row).SetKeyVal(string,string):Call("name",cur.getString(cur.getColumnIndex(ContactsContract.Contacts.DISPLAY_NAME)) )};

			        if (Integer.parseInt(cur.getString(cur.getColumnIndex(ContactsContract.Contacts.HAS_PHONE_NUMBER))) > 0) {
			            Cursor pCur = cr.query(
			                    ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
			                    null,
			                    ContactsContract.CommonDataKinds.Phone.CONTACT_ID +" = ?",
			                    new String[]{id}, null);

			            Object phoneList = @{ForeignDict:Of(row).AddListForKey(string):Call("phone")};
			            while (pCur.moveToNext()) {
			            	Object phoneRow = @{ForeignList:Of(phoneList).NewDictRow():Call()};
			            	@{ForeignDict:Of(phoneRow).SetKeyVal(string,string):Call("phone",
			            		pCur.getString(pCur.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER))
			            		)};
			            }
			            pCur.close();
			        }

					Cursor emailCur = cr.query(
				 				ContactsContract.CommonDataKinds.Email.CONTENT_URI,
				 				null,
				 				ContactsContract.CommonDataKinds.Email.CONTACT_ID + " = ?",
				 				new String[]{id}, null);
					Object emailList = @{ForeignDict:Of(row).AddListForKey(string):Call("email")};
			 		while (emailCur.moveToNext()) {
		            	Object emailRow = @{ForeignList:Of(emailList).NewDictRow():Call()};
		            	@{ForeignDict:Of(emailRow).SetKeyVal(string,string):Call("email",
		            		emailCur.getString(emailCur.getColumnIndex(ContactsContract.CommonDataKinds.Email.DATA))
		            		)};
			 		}
			 		emailCur.close();
			    }
			}
		}
		cur.close();
	@}

    [Foreign(Language.Java)]
  	static extern(android) Java.Object makeContactIntent()
  	@{
        try {
        Intent intent = new Intent(Intent.ACTION_PICK, ContactsContract.Contacts.CONTENT_URI);
        intent.setType(ContactsContract.CommonDataKinds.Phone.CONTENT_TYPE);
        Log.i("testando","intent created - aqui");
        return intent;
      }catch (Exception ex) {
  			return null;
  		}

    @}

   [Foreign(Language.Java)]
    public static extern(android)void OnContactResult(int resultCode, Java.Object intent, object info)  // [2]
    @{
      Log.i("testando","OnResult called");
      Activity a = com.fuse.Activity.getRootActivity();
      Intent i = (Intent) intent;
      try{
        Uri uri = i.getData();
        String[] projection = { ContactsContract.CommonDataKinds.Phone.NUMBER, ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME };
        Cursor cursor = a.getContentResolver().query(uri, projection,null, null, null);
        cursor.moveToFirst();
        String name = cursor.getString(cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME));
        String number = cursor.getString(cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER));
        JSONObject json =new JSONObject();
        json.put("name",name);
        json.put("phone_number",number);
        @{contactResult(string):Call(json.toString())};
        cursor.close();
      }catch(Exception ex) {

  		}

    @}


    [Foreign(Language.Java)]
     public static extern(android)void OnMultipleContactResult(int resultCode, Java.Object intent, object info)  // [2]
     @{
       Log.d("testando","OnMultipleResult called");
       Activity a = com.fuse.Activity.getRootActivity();
       Intent res = (Intent) intent;

       try{
         List<ContactResult> results = MultiContactPicker.obtainResult(res);
         List<String> contacts = new ArrayList<String>();
         JSONArray json = new JSONArray();

         for(int i = 0; i < results.size(); i++){
              JSONObject contactJson = new JSONObject();
              String contactName = results.get(i).getDisplayName();
              contactJson.put("name",contactName);
              JSONArray numbersJson = new JSONArray();
              List<String> numbersArray = results.get(i).getPhoneNumbers();
              for(int y=0; y<numbersArray.size(); y++){
                numbersJson.put(numbersArray.get(y));
              }
              contactJson.put("phone_number",numbersJson);
              json.put(contactJson);
         }

         @{multipleContactResult(string):Call(json.toString())};

       }catch(Exception ex) {

   		}

     @}

    public static void contactResult(string contact)
     {
         Contacts._contactChosen.RaiseAsync(Contacts._contactChosen.ThreadWorker,contact);
     }

     public static void multipleContactResult(string contacts)
      {
          Contacts._multipleContactChosen.RaiseAsync(Contacts._multipleContactChosen.ThreadWorker,contacts);
      }
  public static void PickContactImpl()
	{


  var intent = makeContactIntent();
    var ret =0;
    if (intent!=null)
		{
			ActivityUtils.StartActivity(intent, OnContactResult,ret);
		} else {
			debug_log "Failed to make intent.";
		}

	}

  public static void PickMultipleContactImpl()
	{
    var intent=makeMultipleContactsIntent();

    var ret =0;
    if (intent!=null)
		{
			ActivityUtils.StartActivity(intent, OnMultipleContactResult,ret);
		} else {
			debug_log "Failed to make multiple intent.";
		}

	}


  [Foreign(Language.Java)]
  public static Java.Object makeMultipleContactsIntent()@{
        try {
        Activity a = com.fuse.Activity.getRootActivity();
        Intent intent=new MultiContactPicker.Builder(a).setCompletionText("Adicionar").setSelectionText(" ").setTitleText("Selecione os convidados").MultiContactPickerIntent();
        Log.i("testando","intent created - aqui");
        return intent;
      }catch (Exception ex) {
        return null;
      }

  @}



	private static void AuthorizeResolved(PlatformPermission permission)
	{
		_authorizePromise.Resolve("AuthorizationAuthorized");
	}

	private static void AuthorizeRejected(Exception reason)
	{
		_authorizePromise.Reject(reason);
	}

	static Promise<string> _authorizePromise;

	public static Future<string> AuthorizeImpl()
	{
		//if (_authorizePromise == null)
		//{
			_authorizePromise = new Promise<string>();
			Permissions.Request(Permissions.Android.READ_CONTACTS).Then(AuthorizeResolved, AuthorizeRejected);
		//}
		return _authorizePromise;
	}

}

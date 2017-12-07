trigger BookingBugUserLanguage on User (after update) {
    User NewUser = trigger.new[0]; 
    User OldUser = trigger.old[0]; 

    if(NewUser.get('languagelocalekey') != OldUser.get('languagelocalekey'))
    {
        Object oldval = OldUser.get('languagelocalekey');
        Object newval = NewUser.get('languagelocalekey');
        system.debug('==>valchanged; old val:' + oldval + ' new val:' + newval);
    }
}
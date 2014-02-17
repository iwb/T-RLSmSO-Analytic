function tweet(tweetstr)
persistent TwitterObj PCname;

% Twittern ermöglichen ab Matlab 2013b
versionCheck = version('-java');
if strcmp(versionCheck(1:17), 'Java 1.7.0_11-b21')
    if isempty(TwitterObj)
        load('..\Einstellungen\c.mat')
        TwitterObj = twitty(credentials);
        
        [~, PCname] = system('hostname');
        PCname = PCname(1:3);
    end
    try
        TwitterObj.updateStatus(sprintf([tweetstr '\n_' PCname '_']));
    catch
    end
end
end
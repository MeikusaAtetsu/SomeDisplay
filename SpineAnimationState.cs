using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Spine.Unity;
using Spine;
using System;
//using XLua;


//[CSharpCallLua]
public class SpineAnimationState : MonoBehaviour
{
    public static SpineAnimationState Instance;

    void Awake() 
    { 
        Instance = this;
    }
    public void AnimeStart(SkeletonAnimation skeleton, Action<TrackEntry> action)
    {
        skeleton.AnimationState.Start += delegate (TrackEntry trackEntry)
        {
            action(trackEntry);
        };
    }
    public void AnimeEnd(SkeletonAnimation skeleton, Action<TrackEntry> action)
    {
        skeleton.AnimationState.End += delegate (TrackEntry trackEntry)
        {
            action(trackEntry);
        };
    }
    public void AnimeInterrupt(SkeletonAnimation skeleton, Action<TrackEntry> action)
    {
        skeleton.AnimationState.Interrupt += delegate (TrackEntry trackEntry)
        {
            action(trackEntry);
        };
    }
    public void AnimeComplete(SkeletonAnimation skeleton, Action<TrackEntry> action)
    {
        skeleton.AnimationState.Complete += delegate (TrackEntry trackEntry)
        {
            action(trackEntry);
        };
    }
    public void AnimeEvent(SkeletonAnimation skeleton, Action<object> action)
    {
        skeleton.AnimationState.Event += delegate (TrackEntry trackEntry,Spine.Event evn)
        {
            Dictionary<string, object> dic = new Dictionary<string, object>();
            dic.Add("trackEntry", trackEntry);
            dic.Add("evn", evn);

            action(dic);
        };
    }
}
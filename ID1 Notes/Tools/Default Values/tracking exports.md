# **Using Git to Track, Compare, and Troubleshoot System Configurations**

## **Quick Answer**

Because the snapshot files are just plain CSV text files, you can version them using Git. This lets you compare past snapshots, see exactly what changed, troubleshoot customer issues, and restore older configurations with confidence.

---

# **Explanation and Full Description**

## **1. Why Git Makes This Even More Powerful**

Every snapshot the HMI produces is a simple text file. Git was built to track changes in text.  
That means you can:

- Commit snapshots into a Git repository
    
- Compare the latest snapshot to one taken years earlier
    
- See every edit the customer made
    
- Share files with engineering instantly
    
- Restore older configurations without guessing
    

Git was created by Linus Torvalds, the same guy who built Linux.  
It’s free, it’s fast, and it’s perfect for this workflow.

You can use:

- **Copia**
    
- **GitHub**
    
- **GitLab**
    
- **Bitbucket**  
    Anything that hosts Git repos works.
    

---

## **2. How This Helps Field Service in Real Life**

### **Example Scenario**

1. Field Service commissions a machine and takes a final snapshot.
    
2. They sync that snapshot to their laptop.
    
3. They commit it to the repository as “Final config before turnover.”
    

Two years go by.

4. Customer has been taking snapshots here and there.
    
5. Field Service returns for service.
    
6. They take a fresh snapshot.
    
7. Sync it to their laptop.
    
8. Commit it to the repo.
    

Now you have two commits:

- **Before you left two years ago**
    
- **Today’s current state**
    
You will now have all the snapshots field service and the customer took over the last two years.

### **What You Can Do Now**

You can run a diff (compare) on the two CSV files.

This instantly shows:

- Every setpoint the customer changed
    
- IO config differences
    
- Naming or label changes
    
- Missing channels
    
- Wrong settings
    
- Any configuration drift over time
    

This lets you answer questions like:

- “Why does the system act different than it used to?”
    
- “What did the customer change?”
    
- “How did this get misconfigured?”
    

This is incredibly helpful when the system is behaving oddly and no one knows why.

---

## **3. Great for Troubleshooting and Support**

If the machine is in a weird or impossible configuration:

- Field Service can pull snapshots
    
- Add them to the repo
    
- Send a link to Engineering
    
- Engineering can diff the files remotely
    
- Engineering can fix the configuration in the CSV
    
- Field Service can restore it on-site in seconds
    

No more long phone calls trying to decode customer settings over the phone.  
You literally see the problem line by line.

---

## **4. Makes Restoring Old Configs Easy**

Since everything is stored as text in Git:

- You can always go back to any earlier state
    
- You can grab the exact commit from commissioning day
    
- You can rebuild the entire system configuration from that single file
    

It’s like having a backup of the system from every major event.

---

## **5. Future Possibilities**

Right now, the system saves:

- IO snapshots
    
- Setpoint snapshots
    

But these snapshot functions could grow into tools for:

- Saving tag values during faults
    
- Capturing smooth PID data during process upsets
    
- Recording pressure or flow trends during shutdowns
    
- Dumping key diagnostic data into an “Events” folder
    

Since the snapshot engine can save any tag the HMI can read, this can become a lightweight logging tool for anything we care about.

---

# **Summary**

By combining the snapshot feature with Git, Test Line and Field Service teams get a powerful way to track, compare, and restore configurations. You can:

- See exactly what changed since the last service call
    
- Troubleshoot customer misconfigurations
    
- Share full configurations with Engineering
    
- Restore a clean state in minutesa
    
- Build a long-term history of every machine
    

It turns a simple CSV snapshot into a complete configuration management system.
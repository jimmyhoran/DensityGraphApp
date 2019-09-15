# Density Graph by James Horan

## Getting started

- The app has a simple single project workspace; A Xcode workspace is not needed.
- The only non-system dependency is the `DensityDataAPI` framework.
- The `DensityDataAPI` binary is embedded in the main app bundle only.

To run and test the project;
- Open `DensityGraph.xcodeproj`
- Use the main `DensityGraph` scheme to test and run the application

## File structure

Since the number of app views is minimal, I kept the file structure pretty flat.
In a larger codebase, I most certainly would be using either a MVVM or old school MVC approach.

## Assumptions

The true maximum index of the graphs data set is equal to the `Grid.dataSize - 1`
Each DataPoint is normalised against the lowest and largest multi
Finding the largest value is a prospective approach i.e. the largest value cannot be accurately found without loading the entire data set
The scale of the graph is different each call to getGrid()
DataPoint’s can have the same largest multiple count

## Implementation

I came up with a few options while reviewing the requirements and the DensityDataAPI framework.

### 1) Fixed bounds

DataPoint's bind to a 0%, 50%, 100% opacity value with an animation transition between bounds.

For example:
- Where multi count of DataPoint is 0, opacity = 0%
- Where multi count of DataPoint > 0, opacity = 50%
- Where multi count of DataPoint is the largest at accumulated index (i), opacity would be equal to 100%

With this approach the data relation is retrospective i.e. each data set only loos at the data before it. This means a slice of data could be loaded and then visualised, without having to await the remaining data sets.

### 2) Prospective normalisation (chosen)

With this approach, the largest value is largest multi count of the accumulated data set. The largest and lowest value are the lower and upper values used to normalise each DataPoint of all accumulated data sets over i (index). The result of this approach is the correct visualisation of all data at each index. However the data relation of this approach is prospective i.e. normalising any data in the data set requires all future data.

*There is another option I did consider; similar to my chosen solution, although it would not require all data to be fetched prior to normalising.* Theoretically an accurate prediction of the largest multiple, instead of having to await all data set's, would be a viable approach.

Given `getGrid` provides `dataSize`, `rows` and `columns`, using these parameters would be sufficient to find a suboptimal prediction. If the mean size of each data set was known, a more optimal prediction could be made.

For the purpose of this exercise I chose to stay with option two.

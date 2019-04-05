import turicreate as tc
import sys

if len(sys.argv) != 2:
    print('Incorect number of arguments. Please call with exactly one argument which should be the .csv file specifying the image annotations.')
    sys.exit()
file_name = sys.argv[1]
sFrame = tc.SFrame.read_csv(file_name)
sFrame['image'] = sFrame['image_path'].apply(
    lambda path: tc.Image(path)
)
train_data, test_data = sFrame.random_split(0.8)
model = tc.object_detector.create(sFrame, feature='image', annotations='annotations')
output_model_name = file_name + '.mlmodel'
model.export_coreml(output_model_name)
model.evaluate(train_data, test_data,metric='perplexity')

package flightdelay;

import java.io.IOException;
import java.util.Locale;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.conf.Configured;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.util.Tool;
import org.apache.hadoop.util.ToolRunner;

/**
 * Aggregates delay statistics per (carrier, year, month) over the cleaned flight data.
 * Map output value format (5 longs): total,cancelled,operated,delayed,sum_arr_delay.
 * All five are plain sums, so the same logic works as a combiner (associative and
 * commutative), which shrinks the shuffle.
 */
public class CarrierMonthDelay extends Configured implements Tool {

    private static final int NUM_FIELDS = 23;
    private static final int IDX_YEAR = 1;
    private static final int IDX_MONTH = 2;
    private static final int IDX_CARRIER = 5;
    private static final int IDX_ARR_DELAY = 12;
    private static final int IDX_CANCELLED = 13;
    private static final int IDX_IS_DELAYED = 22;

    static void accumulate(String csv, long[] totals) {
        String[] p = csv.split(",");
        for (int i = 0; i < 5; i++) {
            totals[i] += Long.parseLong(p[i].trim());
        }
    }

    public static class DelayMapper extends Mapper<LongWritable, Text, Text, Text> {
        private final Text outKey = new Text();
        private final Text outVal = new Text();

        @Override
        protected void map(LongWritable key, Text value, Context context)
                throws IOException, InterruptedException {
            String[] f = value.toString().split(",", -1);
            if (f.length < NUM_FIELDS) {
                context.getCounter("FlightDelay", "MalformedLines").increment(1);
                return;
            }
            try {
                String carrier = f[IDX_CARRIER].trim();
                int year = Integer.parseInt(f[IDX_YEAR].trim());
                int month = Integer.parseInt(f[IDX_MONTH].trim());
                long arrDelay = Long.parseLong(f[IDX_ARR_DELAY].trim());
                int cancelled = Integer.parseInt(f[IDX_CANCELLED].trim());
                int delayed = Integer.parseInt(f[IDX_IS_DELAYED].trim());
                int operated = (cancelled == 0) ? 1 : 0;
                long arrSum = (operated == 1) ? arrDelay : 0L;
                outKey.set(carrier + "," + year + "," + month);
                outVal.set("1," + cancelled + "," + operated + "," + delayed + "," + arrSum);
                context.write(outKey, outVal);
                context.getCounter("FlightDelay", "ParsedRecords").increment(1);
            } catch (NumberFormatException e) {
                context.getCounter("FlightDelay", "BadNumberLines").increment(1);
            }
        }
    }

    public static class SumCombiner extends Reducer<Text, Text, Text, Text> {
        private final Text outVal = new Text();

        @Override
        protected void reduce(Text key, Iterable<Text> values, Context context)
                throws IOException, InterruptedException {
            long[] t = new long[5];
            for (Text v : values) {
                accumulate(v.toString(), t);
            }
            outVal.set(t[0] + "," + t[1] + "," + t[2] + "," + t[3] + "," + t[4]);
            context.write(key, outVal);
        }
    }

    public static class DelayReducer extends Reducer<Text, Text, Text, Text> {
        private final Text outVal = new Text();

        @Override
        protected void reduce(Text key, Iterable<Text> values, Context context)
                throws IOException, InterruptedException {
            long[] t = new long[5];
            for (Text v : values) {
                accumulate(v.toString(), t);
            }
            double pct = (t[2] > 0) ? 100.0 * t[3] / t[2] : 0.0;
            double avg = (t[2] > 0) ? (double) t[4] / t[2] : 0.0;
            outVal.set(String.format(Locale.US, "%d,%d,%d,%d,%d,%.2f,%.2f",
                    t[0], t[1], t[2], t[3], t[4], pct, avg));
            context.write(key, outVal);
        }
    }

    @Override
    public int run(String[] args) throws Exception {
        if (args.length != 2) {
            System.err.println("Usage: CarrierMonthDelay <input path or glob> <output path>");
            return 2;
        }
        Configuration conf = getConf();
        conf.set("mapreduce.output.textoutputformat.separator", ",");
        Job job = Job.getInstance(conf, "carrier-month-delay");
        job.setJarByClass(CarrierMonthDelay.class);
        job.setMapperClass(DelayMapper.class);
        job.setCombinerClass(SumCombiner.class);
        job.setReducerClass(DelayReducer.class);
        job.setNumReduceTasks(2);
        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(Text.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);
        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));
        return job.waitForCompletion(true) ? 0 : 1;
    }

    public static void main(String[] args) throws Exception {
        System.exit(ToolRunner.run(new Configuration(), new CarrierMonthDelay(), args));
    }
}

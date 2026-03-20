namespace :embeddings do
  desc "Backfill embeddings for all completed video learnings using Ollama"
  task backfill: :environment do
    scope = VideoLearning.where(status: :completed, embedding: nil)
    total = scope.count
    puts "Generating embeddings for #{total} videos via Ollama (nomic-embed-text)..."

    generator = Embeddings::Generator.new

    scope.find_each.with_index do |vl, i|
      text = Embeddings::VideoLearningEmbedder.new(vl).embeddable_text
      embedding = generator.generate(text)
      vl.update_columns(embedding: embedding, embedding_generated_at: Time.current)
      print "\r#{i + 1}/#{total} done" if (i + 1) % 10 == 0 || i + 1 == total
    rescue => e
      puts "\nFailed for video #{vl.id}: #{e.message}"
    end

    puts "\nDone!"
  end

  desc "Backfill embeddings in batches"
  task batch_backfill: :environment do
    scope = VideoLearning.where(status: :completed, embedding: nil)
    total = scope.count
    puts "Generating embeddings for #{total} videos in batches via Ollama..."

    generator = Embeddings::Generator.new
    done = 0

    scope.find_in_batches(batch_size: 50) do |batch|
      texts = batch.map { |vl| Embeddings::VideoLearningEmbedder.new(vl).embeddable_text }
      embeddings = generator.generate_batch(texts)

      batch.each_with_index do |vl, i|
        vl.update_columns(embedding: embeddings[i], embedding_generated_at: Time.current) if embeddings[i]
      end

      done += batch.size
      puts "#{done}/#{total} done"
    rescue => e
      puts "Batch failed: #{e.message}"
    end

    puts "Done!"
  end
end

using Microsoft.EntityFrameworkCore;
using SmartLoadBulk.Infrastructure.Data.Entities;

namespace SmartLoadBulk.Infrastructure.Data;

public class SmartLoadBulkDbContext(DbContextOptions<SmartLoadBulkDbContext> options) : DbContext(options)
{
    // Master Data
    public DbSet<User> Users => Set<User>();
    public DbSet<Customer> Customers => Set<Customer>();
    public DbSet<Truck> Trucks => Set<Truck>();
    public DbSet<Driver> Drivers => Set<Driver>();
    public DbSet<TruckDriverMap> TruckDriverMaps => Set<TruckDriverMap>();

    // Inventory
    public DbSet<Product> Products => Set<Product>();
    public DbSet<Silo> Silos => Set<Silo>();
    public DbSet<Inventory> Inventories => Set<Inventory>();

    // Order & Queue
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<OrderItem> OrderItems => Set<OrderItem>();
    public DbSet<LoadQueue> LoadQueues => Set<LoadQueue>();

    // Bay & Loading
    public DbSet<Bay> Bays => Set<Bay>();
    public DbSet<LoadJob> LoadJobs => Set<LoadJob>();

    // QR & Verify
    public DbSet<QrToken> QrTokens => Set<QrToken>();
    public DbSet<LoadChecklist> LoadChecklists => Set<LoadChecklist>();

    // Hardware
    public DbSet<HardwareDevice> HardwareDevices => Set<HardwareDevice>();
    public DbSet<HardwareEvent> HardwareEvents => Set<HardwareEvent>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<User>()
            .HasIndex(u => u.Username).IsUnique();

        modelBuilder.Entity<Customer>()
            .HasIndex(c => c.CustomerCode).IsUnique();

        modelBuilder.Entity<Truck>()
            .HasIndex(t => t.LicensePlate).IsUnique();

        modelBuilder.Entity<Driver>()
            .HasIndex(d => d.LicenseNo).IsUnique();

        modelBuilder.Entity<Product>()
            .HasIndex(p => p.ProductCode).IsUnique();

        modelBuilder.Entity<Silo>()
            .HasIndex(s => s.SiloCode).IsUnique();

        modelBuilder.Entity<Silo>()
            .HasOne(s => s.Product)
            .WithMany(p => p.Silos)
            .HasForeignKey(s => s.ProductId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Order>()
            .HasIndex(o => o.OrderCode).IsUnique();

        modelBuilder.Entity<Order>()
            .HasOne(o => o.Customer)
            .WithMany(c => c.Orders)
            .HasForeignKey(o => o.CustomerId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Bay>()
            .HasIndex(b => b.BayCode).IsUnique();

        // Bay → CurrentQueue: no cascade to avoid cycles
        modelBuilder.Entity<Bay>()
            .HasOne(b => b.CurrentQueue)
            .WithMany()
            .HasForeignKey(b => b.CurrentQueueId)
            .OnDelete(DeleteBehavior.SetNull);

        modelBuilder.Entity<LoadJob>()
            .HasOne(j => j.Bay)
            .WithMany(b => b.LoadJobs)
            .HasForeignKey(j => j.BayId)
            .OnDelete(DeleteBehavior.Restrict);

        // Prevent multiple cascade paths on LoadJob
        modelBuilder.Entity<LoadJob>()
            .HasOne(j => j.Order)
            .WithMany()
            .HasForeignKey(j => j.OrderId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<LoadJob>()
            .HasOne(j => j.OrderItem)
            .WithMany()
            .HasForeignKey(j => j.OrderItemId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<LoadJob>()
            .HasOne(j => j.Truck)
            .WithMany()
            .HasForeignKey(j => j.TruckId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<LoadJob>()
            .HasOne(j => j.Driver)
            .WithMany()
            .HasForeignKey(j => j.DriverId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<LoadJob>()
            .HasOne(j => j.Product)
            .WithMany()
            .HasForeignKey(j => j.ProductId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<LoadQueue>()
            .HasOne(q => q.Truck)
            .WithMany(t => t.LoadQueues)
            .HasForeignKey(q => q.TruckId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<LoadQueue>()
            .HasOne(q => q.Driver)
            .WithMany(d => d.LoadQueues)
            .HasForeignKey(q => q.DriverId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<TruckDriverMap>()
            .HasOne(m => m.Truck)
            .WithMany(t => t.TruckDriverMaps)
            .HasForeignKey(m => m.TruckId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<TruckDriverMap>()
            .HasOne(m => m.Driver)
            .WithMany(d => d.TruckDriverMaps)
            .HasForeignKey(m => m.DriverId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
